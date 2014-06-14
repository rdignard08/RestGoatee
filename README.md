RestGoatee
==========

Deserialize objects without the fluff.  No Mappings! No Mindless Repetition! Only Simple!

This framework has no dependencies beyond AFNetworking and the objective-C runtime; it has support for CoreData which can be enabled by importing the CoreData header before (or within) RestGoatee.h; this will expose a new public method: `-[NSObject objectFromJSON:inContext:]` where the `inContext` parameter is a `managedObjectContext` or `nil`.

The optional `RestGoateeSerialization` protocol can be used to provide custom and non-standard mappings and dates from JSON to Objective-C.

# Installation
Using cocoapods add `pod 'RestGoatee'` to your Podfile and run `bash pod install`

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
void foo (id json, ...) { /* your callback when the API returns */
  //...
  for (NSDictionary* dictionary in json) {
    //...
    RGBook* book = [RGBook objectFromJSON:dictionary]; //and that's it!
    //...
  }
  //...
}
```

License
=======
BSD Simplied (2-clause)
