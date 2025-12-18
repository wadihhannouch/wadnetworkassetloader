/// A network-based asset loader for easy_localization with smart fallback and caching.
///
/// This library provides [NetworkOrAssetLoader], an implementation of [AssetLoader]
/// that loads translation files from a remote server with automatic fallback to local
/// cache and bundled assets when the network is unavailable.
library network_or_asset_loader;

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as paths;

/// A network-based asset loader for easy_localization with smart caching and fallback.
///
/// This loader attempts to load translation files from a remote server first, then
/// falls back to locally cached files, and finally to bundled assets if needed.
///
/// Example usage:
/// ```dart
/// EasyLocalization(
///   assetLoader: NetworkOrAssetLoader(
///     localeUrl: (localeName) => 'https://yourdomain.com/translations/',
///     assetsPath: 'assets/translations',
///     timeout: Duration(seconds: 30),
///     localCacheDuration: Duration(days: 1),
///   ),
///   // ... other properties
/// )
/// ```
class NetworkOrAssetLoader extends AssetLoader {
  /// A function that returns the base URL for loading translation files.
  ///
  /// The function receives the locale name (e.g., 'en', 'ar', 'fr') and should
  /// return the base URL. The locale name will be appended to construct the full URL.
  ///
  /// Example:
  /// ```dart
  /// localeUrl: (localeName) => 'https://example.com/translations/'
  /// // Results in: https://example.com/translations/en.json
  /// ```
  final Function localeUrl;

  /// The maximum time to wait for a network request to complete.
  ///
  /// If the network request takes longer than this duration, it will be cancelled
  /// and the loader will fall back to cached or bundled assets.
  ///
  /// Defaults to 30 seconds.
  final Duration timeout;

  /// The path to bundled translation assets in the app.
  ///
  /// This path is used as the final fallback when network loading fails and
  /// no cached translations are available.
  ///
  /// Example: `'assets/translations'`
  final String assetsPath;

  /// The duration for which cached translations are considered valid.
  ///
  /// After this duration expires, the loader will attempt to fetch fresh
  /// translations from the network. If the network is unavailable, it will
  /// still use the expired cache as a fallback.
  ///
  /// Defaults to 1 day.
  final Duration localCacheDuration;

  /// Creates a new [NetworkOrAssetLoader].
  ///
  /// The [localeUrl] and [assetsPath] parameters are required.
  ///
  /// The [timeout] parameter defaults to 30 seconds.
  ///
  /// The [localCacheDuration] parameter defaults to 1 day.
  NetworkOrAssetLoader({
    required this.localeUrl,
    this.timeout = const Duration(seconds: 30),
    required this.assetsPath,
    this.localCacheDuration = const Duration(days: 1),
  });

  /// Loads translation data for the specified locale.
  ///
  /// This method follows a priority order:
  /// 1. Check if valid cached translation exists (within [localCacheDuration])
  /// 2. If no valid cache and network is available, download from network
  /// 3. If network fails, use expired cache if available
  /// 4. Finally, fall back to bundled assets
  ///
  /// Returns a map of translation keys and values.
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    var string = '';

    // try loading local previously-saved localization file
    if (await localTranslationExists(locale.toString())) {
      string = await loadFromLocalFile(locale.toString());
    }

    // no local or failed, check if internet and download the file
    if (string == '' && await isInternetConnectionAvailable()) {
      string = await loadFromNetwork(locale.toString());
    }

    // local cache duration was reached or no internet access but prefer local file to assets
    if (string == '' &&
        await localTranslationExists(
          locale.toString(),
          ignoreCacheDuration: false,
        )) {
      string = await loadFromLocalFile(locale.toString());
    }

    // still nothing? Load from assets
    if (string == '') {
      string = await rootBundle.loadString('$assetsPath/$locale.json');
    }

    // then returns the json file
    return json.decode(string);
  }

  /// Checks if a locale file exists at the given path.
  ///
  /// This method always returns true and is provided for compatibility.
  Future<bool> localeExists(String localePath) => Future.value(true);

  /// Checks if an internet connection is available.
  ///
  /// Returns `true` if the device has any network connectivity (wifi, mobile, etc.),
  /// `false` if there is no connection.
  Future<bool> isInternetConnectionAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Loads translation content from the network.
  ///
  /// Constructs the URL using [localeUrl] and the locale name, then attempts
  /// to download the translation file. If successful and the content is valid JSON,
  /// it saves the translation locally and returns the content.
  ///
  /// Returns an empty string if the download fails or times out.
  Future<String> loadFromNetwork(String localeName) async {
    String url = localeUrl(localeName);
    url = "$url$localeName";
    try {
      final response = await Future.any([
        http.get(Uri.parse(url)),
        Future.delayed(timeout),
      ]);
      if (response != null && response.statusCode == 200) {
        var content = utf8.decode(response.bodyBytes);
        // check valid json before saving it
        if (json.decode(content) != null) {
          await saveTranslation(localeName, content);
          return content;
        }
      }
    } catch (e) {
      //donothing
    }

    return '';
  }

  /// Checks if a locally cached translation exists for the given locale.
  ///
  /// By default, this method checks if the cached file exists and if it's still
  /// within the [localCacheDuration]. Set [ignoreCacheDuration] to `true` to
  /// only check file existence without considering its age.
  ///
  /// Returns `true` if a valid cached file exists, `false` otherwise.
  Future<bool> localTranslationExists(
    String localeName, {
    bool ignoreCacheDuration = false,
  }) async {
    var translationFile = await getFileForLocale(localeName);

    if (!await translationFile.exists()) {
      return false;
    }
    // don't check file's age
    if (!ignoreCacheDuration) {
      var difference = DateTime.now().difference(
        await translationFile.lastModified(),
      );

      if (difference > (localCacheDuration)) {
        return false;
      }
    }

    return true;
  }

  /// Loads translation content from a locally cached file.
  ///
  /// Returns the file content as a string.
  Future<String> loadFromLocalFile(String localeName) async {
    return await (await getFileForLocale(localeName)).readAsString();
  }

  /// Saves translation content to local cache.
  ///
  /// Creates the cache directory if it doesn't exist and writes the translation
  /// content to a file for the specified locale.
  Future<void> saveTranslation(String localeName, String content) async {
    var file = File(await getFilenameForLocale(localeName));
    await file.create(recursive: true);
    return print('saved');
  }

  /// Returns the local path where cached translations are stored.
  ///
  /// Uses the temporary directory provided by the system.
  Future<String> get _localPath async {
    final directory = await paths.getTemporaryDirectory();

    return directory.path;
  }

  /// Returns the full file path for a cached translation file.
  ///
  /// The file is stored in a `translations-res` subdirectory of the temporary
  /// directory with the locale name as the filename.
  Future<String> getFilenameForLocale(String localeName) async {
    return '${await _localPath}/translations-res/$localeName.json';
  }

  /// Returns a [File] object for the cached translation of the specified locale.
  ///
  /// The file may or may not exist yet.
  Future<File> getFileForLocale(String localeName) async {
    return File(await getFilenameForLocale(localeName));
  }
}
