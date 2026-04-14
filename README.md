# NetworkOrAssetLoader

A Flutter package that provides a network-based asset loader for [easy_localization](https://pub.dev/packages/easy_localization) with smart fallback and caching capabilities.

## Features

- **Network-first loading**: Downloads translation files from a remote server
- **Smart caching**: Saves translations locally for offline access
- **Automatic fallback**: Falls back to local cache or bundled assets when network is unavailable
- **Cache expiration**: Configurable cache duration to ensure translations stay up-to-date
- **Connectivity awareness**: Automatically detects network availability before attempting downloads
- **Timeout handling**: Configurable network request timeout
- **Force refresh**: Option to bypass cache and always fetch from the network
- **Source tracking**: Optional callback to know where translations were loaded from
- **Custom HTTP client**: Inject your own HTTP client for auth headers, interceptors, or testing

## Getting Started

### 1. Install dependencies

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  network_or_asset_loader: ^0.0.8
  easy_localization: ^3.0.8
```

Then run:

```bash
flutter pub get
```

### 2. Prepare local translation files

Create JSON translation files in your assets folder. Each file should be named with the locale code (e.g. `en.json`, `ar.json`, `fr.json`) and contain a flat key-value map:

```
assets/
  translations/
    en.json
    ar.json
    fr.json
```

Example `en.json`:

```json
{
  "app_title": "My App",
  "welcome_message": "Welcome!",
  "description": "This is a sample app."
}
```

### 3. Register assets in `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/translations/
```

### 4. Host translation files on your server

Place the same JSON files on your remote server so they are accessible via URL. The `localeUrl` callback receives the locale name and must return the **full URL** to the JSON file. For example:

```dart
localeUrl: (String localeName) => 'https://yourdomain.com/translations/$localeName.json'
```

This will request:

- `https://yourdomain.com/translations/en.json`
- `https://yourdomain.com/translations/ar.json`
- `https://yourdomain.com/translations/fr.json`

If your project uses an API endpoint class, you can reference it directly:

```dart
localeUrl: (String localeName) => '${ApiEndpoint.baseUrl}/$localeName.json'
```

### 5. Platform-specific setup

#### Android

Add internet permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS

No extra setup needed — iOS allows outgoing network requests by default.

## Usage

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:network_or_asset_loader/network_or_asset_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: NetworkOrAssetLoader(
        localeUrl: (String localeName) =>
            'https://yourdomain.com/translations/$localeName.json',
        assetsPath: 'assets/translations',
      ),
      child: const MyApp(),
    ),
  );
}
```

### Using Translations in Widgets

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // These 3 lines are required for easy_localization to work
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app_title'.tr())),
      body: Center(
        child: Text('welcome_message'.tr()),
      ),
    );
  }
}
```

### Switching Locale at Runtime

```dart
// Change to Arabic
await context.setLocale(const Locale('ar'));

// Change to French
await context.setLocale(const Locale('fr'));
```

### Custom Timeout and Cache Duration

```dart
NetworkOrAssetLoader(
  localeUrl: (String localeName) =>
      '${ApiEndpoint.baseUrl}/$localeName.json',
  assetsPath: 'assets/translations',
  // Wait up to 10 seconds for network response (default: 30s)
  timeout: const Duration(seconds: 10),
  // Re-fetch from server every 12 hours instead of every day (default: 1 day)
  localCacheDuration: const Duration(hours: 12),
)
```

### Force Refresh (Bypass Cache)

Set `forceRefresh: true` to always fetch from the network, ignoring any cached translations. Useful after an app update or when the user manually triggers a refresh:

```dart
NetworkOrAssetLoader(
  localeUrl: (String localeName) =>
      '${ApiEndpoint.baseUrl}/$localeName.json',
  assetsPath: 'assets/translations',
  forceRefresh: true,
)
```

### Source Tracking (Debugging)

Use the `onSourceResolved` callback to know where translations were loaded from. The callback receives the locale name and a `TranslationSource` enum:

```dart
NetworkOrAssetLoader(
  localeUrl: (String localeName) =>
      '${ApiEndpoint.baseUrl}/$localeName.json',
  assetsPath: 'assets/translations',
  onSourceResolved: (locale, source) {
    debugPrint('Locale "$locale" loaded from: $source');
    // source is one of:
    //   TranslationSource.cache        — valid local cache
    //   TranslationSource.network      — downloaded from server
    //   TranslationSource.expiredCache — expired cache used as fallback
    //   TranslationSource.asset        — bundled app assets
  },
)
```

### Custom HTTP Client

Inject your own `http.Client` to add authorization headers, custom certificates, or for testing:

```dart
import 'package:http/http.dart' as http;

final client = http.Client(); // or your custom client

NetworkOrAssetLoader(
  localeUrl: (String localeName) =>
      '${ApiEndpoint.baseUrl}/$localeName.json',
  assetsPath: 'assets/translations',
  httpClient: client,
)
```

## Constructor Parameters

| Parameter            | Type                          | Required | Default                | Description                                                                 |
|----------------------|-------------------------------|----------|------------------------|-----------------------------------------------------------------------------|
| `localeUrl`          | `String Function(String)`     | Yes      | —                      | A function that receives the locale name (e.g. `en`, `ar`) and returns the **full URL** to the translation JSON file. |
| `assetsPath`         | `String`                      | Yes      | —                      | Path to the bundled translation assets in your app (used as the final fallback). |
| `timeout`            | `Duration`                    | No       | `Duration(seconds: 30)` | Maximum time to wait for a network response before falling back. |
| `localCacheDuration` | `Duration`                    | No       | `Duration(days: 1)`     | How long cached translations are considered valid before re-fetching. |
| `httpClient`         | `http.Client?`                | No       | `null`                 | Custom HTTP client for auth headers, interceptors, or testing. If not provided, a default client is used per request. |
| `forceRefresh`       | `bool`                        | No       | `false`                | When `true`, skips cache and always fetches from the network first. Falls back to cache/assets on failure. |
| `onSourceResolved`   | `void Function(String, TranslationSource)?` | No | `null`          | Callback invoked after translations load, reporting the locale and the source used (`cache`, `network`, `expiredCache`, or `asset`). |

## How It Works

The loader follows this priority order when loading translations:

```
1. Valid local cache exists?
   └─ Yes → Use cached translation ✅
   └─ No  ↓
2. Internet available?
   └─ Yes → Download from server, save to cache ✅
   └─ No  ↓
3. Expired local cache exists?
   └─ Yes → Use expired cache (better than nothing) ✅
   └─ No  ↓
4. Load from bundled assets ✅
```

This ensures the app **always has translations available**, whether the user is online or offline:

- **Online (first launch)**: Downloads from the server and caches locally.
- **Online (cache valid)**: Uses the local cache for instant loading — no network request.
- **Online (cache expired)**: Downloads fresh translations from the server.
- **Offline (cache available)**: Uses the cached translation regardless of age.
- **Offline (no cache)**: Falls back to the bundled asset files shipped with the app.

## Additional Information

**Repository**: [https://github.com/wadihhannouch/wadnetworkassetloader](https://github.com/wadihhannouch/wadnetworkassetloader)

**Issues**: Please file issues on the [GitHub issue tracker](https://github.com/wadihhannouch/wadnetworkassetloader/issues)

**Contributing**: Contributions are welcome! Please feel free to submit a Pull Request.
