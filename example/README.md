# NetworkOrAssetLoader Example

This example demonstrates how to use the `network_or_asset_loader` package with `easy_localization` to load translations from a network source with automatic fallback and caching.

## Features Demonstrated

- Network-based translation loading
- Automatic fallback to local cache
- Bundled asset fallback when offline
- Multi-language support (English, Arabic, French)
- Language switching functionality
- Cache duration configuration

## Running the Example

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Configuration

The example uses a placeholder URL for the network translations. To use actual network translations:

1. Host your translation JSON files on a web server
2. Update the `localeUrl` in `lib/main.dart`:
   ```dart
   localeUrl: (localeName) => 'https://your-actual-domain.com/translations/',
   ```

## How It Works

The app will:
1. First attempt to load translations from the network URL
2. If network is unavailable or fails, use the local cached version
3. If no cache exists, fall back to the bundled assets in `assets/translations/`

## File Structure

```
example/
├── lib/
│   └── main.dart          # Main app with WadNetworkAssetLoader setup
├── assets/
│   └── translations/      # Bundled translation files (fallback)
│       ├── en.json
│       ├── ar.json
│       └── fr.json
└── pubspec.yaml           # Dependencies and asset configuration
```

## Customization

You can customize the loader behavior by adjusting these parameters:

- `timeout`: Network request timeout (default: 30 seconds)
- `localCacheDuration`: How long to keep cached translations (default: 1 day)
- `assetsPath`: Path to bundled translation assets
- `localeUrl`: Function that returns the base URL for translations
