# WadNetworkAssetLoader

A Flutter package that provides a network-based asset loader for easy_localization with smart fallback and caching capabilities.

## Features

- **Network-first loading**: Downloads translation files from a remote server
- **Smart caching**: Saves translations locally for offline access
- **Automatic fallback**: Falls back to local cache or bundled assets when network is unavailable
- **Cache expiration**: Configurable cache duration to ensure translations stay up-to-date
- **Connectivity awareness**: Automatically detects network availability before attempting downloads
- **Timeout handling**: Configurable network request timeout

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  wadnetworkassetloader: ^0.0.1
  easy_localization: ^3.0.7
```

Ensure you have translation JSON files both in your assets folder and available on a remote server.

Add your local assets to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/translations/
```

## Usage

Basic implementation with `easy_localization`:

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wadnetworkassetloader/wadnetworkassetloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('ar'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      assetLoader: WadNetworkAssetLoader(
        localeUrl: (localeName) => 'https://yourdomain.com/translations/',
        assetsPath: 'assets/translations',
        timeout: Duration(seconds: 30),
        localCacheDuration: Duration(days: 1),
      ),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: HomeScreen(),
    );
  }
}
```

### Constructor Parameters

- `localeUrl` (required): A function that returns the base URL for translation files
- `assetsPath` (required): Path to local bundled translation assets
- `timeout`: Network request timeout (default: 30 seconds)
- `localCacheDuration`: How long to keep cached translations (default: 1 day)

## How it works

The loader follows this priority order:

1. **Check local cache**: If a valid cached translation exists (within cache duration), use it
2. **Try network**: If no valid cache and internet is available, download from the network
3. **Fallback to expired cache**: If network fails but expired cache exists, use it
4. **Use bundled assets**: If all else fails, load from the app's bundled assets

Translations downloaded from the network are automatically saved to local storage for future offline use.

## Additional information

**Repository**: [https://github.com/wadihhannouch/wadnetworkassetloader](https://github.com/wadihhannouch/wadnetworkassetloader)

**Issues**: Please file issues on the [GitHub issue tracker](https://github.com/wadihhannouch/wadnetworkassetloader/issues)

**Contributing**: Contributions are welcome! Please feel free to submit a Pull Request.
