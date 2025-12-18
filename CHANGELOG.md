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
