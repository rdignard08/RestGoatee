RestGoatee
==========

Backported to iOS 6.0 and AFNetworking 1.3.3

Deserialize objects without the fluff.  No Mappings! No Mindless Repetition! Only Simple!
This framework has no dependencies beyond AFNetworking (Any version between latest and 1.3.3) and the objective-C runtime, and it supports CoreData out of the box.  Whether you use CoreData or not it will simply work.
The optional `RestGoateeSerialization` protocol can be used to provide custom and non-standard mappings and dates from JSON to Objective-C.
By default, a key in the json of `foo_bar` will be automatically mapped to a property of name `fooBar`.  You only need to provide mappings for keys which don't match in "canonical form".

Why _RestGoatee_?
=================
Consider your favorite or most popular model framework:

  * Does it require explicit mappings to get even simple objects built?  this doesn't
  * Does it support `NSManagedObject` subclasses? this does
  * Does it intelligently map between snake case (foo-bar) or C case (foo_bar) or camel case (fooBar)? this does

# Installation
Using cocoapods add `pod 'RestGoatee'` to your Podfile and run `pod install`

A feature I've called "Server Typing" can be enabled by calling `rg_setServerTypeKey` with your desired key before you make the first call to any method on `RGAPIClient`.  Changing it will propagate, but not in any manner that will be safe or predicable.

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
