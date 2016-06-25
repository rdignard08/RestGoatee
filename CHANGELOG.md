# RestGoatee CHANGELOG

## 2.6.3
- Added support for OS X (10.9)

## 2.6.2
- Primary key based deserialization now supports the key being an attribute when handling XML
- Two exceptional cases have been given specific asserts to better aid debugging

## 2.6.1
- Updated README.md such that the lowest supported version of iOS is 7.0 (and Mac equivalent)
- Binary search slightly changed when searching for existing managed objects

## 2.6.0
- Upgraded support to AFNetworking to 3.x
- Upgraded RestGoatee-Core reference to use any 2.2+ version
- Duplicate objects within the same response will be ignored (warning generated)
- The `NSURLResponse` and `NSURLRequest` in `shouldRetryRequest:response:error:retryCount:` are nullable
- Branch coverage at 95%

## 2.5.1
- Delegate and convenience methods on `RGAPIClient` have been removed
- Project is completely nullability annotated
- Project has CI testing provided by TravisCI
- New delegate method on `RGSerializationDelegate` to handle retry logic
- Podspec is version locked to AFNetworking major version 2, and RestGoatee-Core 2.1.5
- Support for swift package manager
- UIImageView+RGImageDownload provides a rudimentary image downloading and caching system

## 0.1.0

Initial release.
