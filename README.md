RestGoatee
==========

Deserialize objects without the fluff.  No Mappings! No Mindless Repetition! Only Simple!
This framework has no dependencies beyond AFNetworking and the objective-C runtime, and it supports CoreData out of the box.  Whether you use CoreData or not it will simply work.
The optional `RestGoateeSerialization` protocol can be used to provide custom and non-standard mappings and dates from JSON to Objective-C.
By default, a key in the json of `foo_bar` will be automatically mapped to a property of name `fooBar`.  You only need to provide mappings for keys which don't match in "canonical form".

Why _RestGoatee_?
=================
Consider your favorite or most popular model framework:

  * Does it require explicit mappings to get even simple objects built?  this doesn't
  * Does it support `NSManagedObject` subclasses? this does
  * Does it intelligently map between snake case (foo-bar) or C case (foo_bar) or camel case (fooBar)? this does
  * Does it intelligently detect the best `NSDate` format to capture the most information? this does

# Installation
Using cocoapods add `pod 'RestGoatee'` to your Podfile and run `pod install`

A feature I've called "Server Typing", which gives the server the opportunity to designate what client-side class is suited for a given dictionary, is disabled by default.  You can edit `rg_serverTypeKey()` to return the appropriate key should this behavior be desired.

Example
=======
This example is available in RestGoateeExample; you will need to `pod install` the module.

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
  [self GET:@"/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGBook class] completion:^(RGResponseObject* response) {
    //something...
  }];
}
```

License
=======
BSD Simplied (2-clause)
