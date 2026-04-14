/// A network-based asset loader for easy_localization with smart fallback and caching.
///
/// This library provides [NetworkOrAssetLoader], an implementation of [AssetLoader]
/// that loads translation files from a remote server with automatic fallback to local
/// cache and bundled assets when the network is unavailable.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as paths;

/// The source from which translations were loaded.
enum TranslationSource {
  /// Translations loaded from a valid (non-expired) local cache.
  cache,

  /// Translations downloaded from the network.
  network,

  /// Translations loaded from an expired local cache as a fallback.
  expiredCache,

  /// Translations loaded from bundled app assets.
  asset,
}

/// A network-based asset loader for easy_localization with smart caching and fallback.
///
/// This loader attempts to load translation files from a remote server first, then
/// falls back to locally cached files, and finally to bundled assets if needed.
///
/// Example usage:
/// ```dart
/// EasyLocalization(
///   assetLoader: NetworkOrAssetLoader(
///     localeUrl: (localeName) => 'https://yourdomain.com/translations/$localeName.json',
///     assetsPath: 'assets/translations',
///     timeout: Duration(seconds: 30),
///     localCacheDuration: Duration(days: 1),
///     onSourceResolved: (locale, source) {
///       debugPrint('Locale $locale loaded from $source');
///     },
///   ),
///   // ... other properties
/// )
/// ```
class NetworkOrAssetLoader extends AssetLoader {
  /// A function that returns the full URL for a translation file.
  ///
  /// The function receives the locale name (e.g., 'en', 'ar', 'fr') and should
  /// return the complete URL to the JSON translation file.
  ///
  /// Example:
  /// ```dart
  /// localeUrl: (localeName) => 'https://example.com/translations/$localeName.json'
  /// ```
  final String Function(String localeName) localeUrl;

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

  /// An optional HTTP client for making network requests.
  ///
  /// If not provided, a default [http.Client] is created for each request.
  /// Pass a custom client to add interceptors, auth headers, or custom
  /// certificates, and to facilitate testing.
  final http.Client? httpClient;

  /// Whether to bypass the cache and always fetch from the network.
  ///
  /// When `true`, the loader skips the cache check and goes straight to
  /// the network. If the network fails, it still falls back to cache/assets.
  ///
  /// Defaults to `false`.
  final bool forceRefresh;

  /// An optional callback invoked after translations are loaded.
  ///
  /// Receives the locale name and the [TranslationSource] indicating where
  /// the translations were loaded from. Useful for debugging and analytics.
  final void Function(String locale, TranslationSource source)?
  onSourceResolved;

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
    this.httpClient,
    this.forceRefresh = false,
    this.onSourceResolved,
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
    var source = TranslationSource.asset;

    // try loading local previously-saved localization file (if not forcing refresh)
    if (!forceRefresh &&
        await localTranslationExists(
          locale.toString(),
          checkCacheDuration: true,
        )) {
      string = await loadFromLocalFile(locale.toString());
      source = TranslationSource.cache;
    }

    // no local or failed, check if internet and download the file
    if (string == '' && await isInternetConnectionAvailable()) {
      string = await loadFromNetwork(locale.toString());
      if (string != '') {
        source = TranslationSource.network;
      }
    }

    // no internet access or network failed — use expired cache if available
    if (string == '' &&
        await localTranslationExists(
          locale.toString(),
          checkCacheDuration: false,
        )) {
      string = await loadFromLocalFile(locale.toString());
      source = TranslationSource.expiredCache;
    }

    // still nothing? Load from assets
    if (string == '') {
      string = await rootBundle.loadString('$assetsPath/$locale.json');
      source = TranslationSource.asset;
    }

    onSourceResolved?.call(locale.toString(), source);

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
    final client = httpClient ?? http.Client();
    final shouldCloseClient = httpClient == null;
    try {
      final response = await client.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode == 200) {
        var content = utf8.decode(response.bodyBytes);
        // check valid json before saving it
        if (json.decode(content) != null) {
          await saveTranslation(localeName, content);
          return content;
        }
      }
    } on TimeoutException {
      // network request timed out — fall through to return empty
    } catch (e) {
      // network error — fall through to return empty
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }

    return '';
  }

  /// Checks if a locally cached translation exists for the given locale.
  ///
  /// When [checkCacheDuration] is `true`, the method also checks whether the
  /// cached file is still within the [localCacheDuration]. When `false`, only
  /// file existence is checked regardless of age.
  ///
  /// Returns `true` if a valid cached file exists, `false` otherwise.
  Future<bool> localTranslationExists(
    String localeName, {
    bool checkCacheDuration = true,
  }) async {
    var translationFile = await getFileForLocale(localeName);

    if (!await translationFile.exists()) {
      return false;
    }
    // check file's age only when requested
    if (checkCacheDuration) {
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
    await file.writeAsString(content);
  }

  /// Returns the local path where cached translations are stored.
  ///
  /// Uses the application support directory for persistent caching.
  Future<String> get _localPath async {
    final directory = await paths.getApplicationSupportDirectory();

    return directory.path;
  }

  /// Returns the full file path for a cached translation file.
  ///
  /// The file is stored in a `translations-res` subdirectory of the
  /// application support directory with the locale name as the filename.
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
