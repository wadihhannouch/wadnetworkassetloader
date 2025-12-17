
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as paths;

class WadNetworkAssetLoader extends AssetLoader {
  final Function localeUrl;

  final Duration timeout;

  final String assetsPath;

  final Duration localCacheDuration;

  WadNetworkAssetLoader(
      {required this.localeUrl,
        this.timeout = const Duration(seconds: 30),
        required this.assetsPath,
        this.localCacheDuration = const Duration(days: 1)});

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
        await localTranslationExists(locale.toString(), ignoreCacheDuration: false)) {
      string = await loadFromLocalFile(locale.toString());
    }

    // still nothing? Load from assets
    if (string == '') {
      string = await rootBundle.loadString('$assetsPath/$locale.json');
    }

    // then returns the json file
    return json.decode(string);
  }

  Future<bool> localeExists(String localePath) => Future.value(true);

  Future<bool> isInternetConnectionAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.none ? false : true;
  }

  Future<String> loadFromNetwork(String localeName) async {
    String url = localeUrl(localeName);
    url = "$url$localeName";
    print(url);
    try {
      final response = await Future.any([http.get(Uri.parse(url)), Future.delayed(timeout)]);
      print(response);
      if (response != null && response.statusCode == 200) {
        var content = utf8.decode(response.bodyBytes);
        // check valid json before saving it
        if (json.decode(content) != null) {
          await saveTranslation(localeName, content);
          return content;
        }
      }
    } catch (e) {
      print(e.toString());
    }

    return '';
  }

  Future<bool> localTranslationExists(String localeName, {bool ignoreCacheDuration = false}) async {
    var translationFile = await getFileForLocale(localeName);

    if (!await translationFile.exists()) {
      return false;
    }
    // don't check file's age
    if (!ignoreCacheDuration) {
      var difference = DateTime.now().difference(await translationFile.lastModified());

      if (difference > (localCacheDuration)) {
        return false;
      }
    }

    return true;
  }

  Future<String> loadFromLocalFile(String localeName) async {
    return await (await getFileForLocale(localeName)).readAsString();
  }

  Future<void> saveTranslation(String localeName, String content) async {
    var file = File(await getFilenameForLocale(localeName));
    await file.create(recursive: true);
    return print('saved');
  }

  Future<String> get _localPath async {
    final directory = await paths.getTemporaryDirectory();

    return directory.path;
  }

  Future<String> getFilenameForLocale(String localeName) async {
    return '${await _localPath}/translations-res/$localeName.json';
  }

  Future<File> getFileForLocale(String localeName) async {
    return File(await getFilenameForLocale(localeName));
  }
}
