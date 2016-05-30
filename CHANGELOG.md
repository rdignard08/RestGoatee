# RestGoatee CHANGELOG

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
