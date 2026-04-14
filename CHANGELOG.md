## 0.0.8

* **Bug Fix**: `saveTranslation` now writes content to the file (caching was previously non-functional)
* **Bug Fix**: Fixed inverted cache duration logic in `localTranslationExists` — renamed `ignoreCacheDuration` to `checkCacheDuration` for clarity
* **Bug Fix**: Fixed timeout race condition — replaced `Future.any` with proper `.timeout()` to avoid leaked HTTP requests
* **Improvement**: Cache is now stored in `getApplicationSupportDirectory()` instead of `getTemporaryDirectory()` for reliable persistence
* **Improvement**: `localeUrl` is now strongly typed as `String Function(String)` instead of `Function`
* **Feature**: Added `httpClient` parameter — inject a custom `http.Client` for auth headers, interceptors, or testing
* **Feature**: Added `forceRefresh` parameter — bypass cache and always fetch from the network
* **Feature**: Added `onSourceResolved` callback — get notified which source translations were loaded from (cache, network, expiredCache, or asset)
* **Feature**: Added `TranslationSource` enum for source tracking

## 0.0.6

* Minor updates and improvements

## 0.0.5

* Updated GitHub Actions workflow to use latest stable Flutter version
* Fixed workflow compatibility issues

## 0.0.4

* Fixed library file naming to use underscores (network_or_asset_loader.dart)
* Updated all import statements to use correct package and file names
* Added GitHub Actions workflow for automated publishing
* Minor documentation improvements

## 0.0.3

* **Breaking Change**: Renamed class from `EasyNetworkAssetLoader` to `NetworkOrAssetLoader`
* **Breaking Change**: Package name changed from `network-or-asset-loader` to `network_or_asset_loader`
* Improved naming clarity and consistency

## 0.0.2

* **Breaking Change**: Renamed class from `WadNetworkAssetLoader` to `EasyNetworkAssetLoader`
* Updated `connectivity_plus` dependency to version 7.0.0
* Fixed connectivity check to work with new API that returns `List<ConnectivityResult>`
* Added comprehensive documentation comments to all public API elements
* Improved code documentation and examples

## 0.0.1

* Initial release
* Network-based translation loading with smart caching
* Automatic fallback to local cache and bundled assets
* Configurable cache duration and network timeout
* Support for easy_localization package
