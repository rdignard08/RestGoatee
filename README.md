RestGoatee
==========

Deserialize objects without the fluff.  No Mappings! No Mindless Repetition! Only Simple!

This framework has no dependencies beyond AFNetworking and the objective-C runtime; it has support for CoreData which can be enabled by importing the CoreData header before (or within) RestGoatee.h; this will expose a new public method: `-[NSObject objectFromJSON:inContext:]` where the `inContext` parameter is a `managedObjectContext` or `nil`.

The optional `RestGoateeSerialization` protocol can be used to provide custom and non-standard mappings and dates from JSON to Objective-C.

By default, a key in the json of `foo_bar` will be automatically mapped to a property of name `fooBar`.  You only need to provide mappings for keys which don't match in "canonical form".

# Installation
Using cocoapods add `pod 'RestGoatee'` to your Podfile and run `pod install`

Example
=======
Using this framework, Let's look at turning a request to [iTunes Search API](https://itunes.apple.com/search?term=pink+floyd) into objects...
## Model

```objc
@interface RGBook : NSObject

@property (nonatomic, strong) NSString* artistName;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NSArray* genres;
@property (nonatomic, strong) NSDate* releaseDate;
@property (nonatomic, strong) NSNumber* trackId;
@property (nonatomic, strong) NSString* trackName;

@end
```
```objc
@implementation RGBook @end //nothing!
```

## In your API...

```objc
void foo (...) { /* your invocation of the API */
  [self GET:@"/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGBook class] completion:^(id response, NSError* error) {
    NSLog([response[0] class]); // outputs RGBook
  }];
}
```

License
=======
BSD Simplied (2-clause)
