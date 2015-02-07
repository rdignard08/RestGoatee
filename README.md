RestGoatee
==========

RestGoatee is an add-on framework to AFNetworking; taking the raw `NSDictionary` and `NSXMLParser` responses and convienently converts them to your own objects.

Supports: iOS 6.0+ and AFNetworking 2.0.0+, branch v1.5.4 supports down to AFNetworking 1.3.3 (does not have XML support).

This library's aim is one of simplicity in the common case and extensibility in the general case:<br/>
1) The "API reponse to working objects" operation is not the place for business logic or key translation.<br/>
2) The API layer should be able to handle new objects and object properties seemlessly without requiring new deserialization logic.  For example, this <a href="https://github.com/rdignard08/RestGoatee/commit/50b516c4e5377ef02a384b26ce94984655b424f0">commit</a> added an entirely new response object to the example project without fanfare.<br/>
3) Due to JSON and XML having limited types, the deserializer needs to be able to intelligently map to a larger standard family of types.<br/>
4) CoreData support is usually not done at the outset of a project; this library makes it easier to turn it on with minimal refactoring.  CoreData support is implicit, but inactive in projects without it.<br/>
5) The default mapping behavior should be both generally intuitive (correct 99% of the time) and extensible.<br/>
6) The default should be the least verbose in terms of complexity and lines of code.  You don't specify mappings for objects that are obviously one-to-one and well-named.

Why _RestGoatee_?
=================
Consider your favorite or most popular model framework:

  * Does it require explicit mappings to get even simple objects built?  <img src="https://github.com/jloughry/Unicode/raw/master/graphics/red_x.png"/>
  * Does it support `NSManagedObject` subclasses? <img src="https://github.com/jloughry/Unicode/raw/master/graphics/green_check.png"/>
  * Does it intelligently map between snake case (foo-bar) or C case (foo_bar) or camel case (fooBar)? <img src="https://github.com/jloughry/Unicode/raw/master/graphics/green_check.png"/>
  * JSON or XML? <img src="https://github.com/jloughry/Unicode/raw/master/graphics/green_check.png"/>

# Installation
Using cocoapods add `pod 'RestGoatee'` to your Podfile and run `pod install`

A feature I've called "Server Typing" can be enabled by calling `rg_setServerTypeKey` with your desired key before you make the first call to any method on `RGAPIClient`.  You are highly advised to not changing this during the operation of your app; if you enable it, it ought to be something generally available on all objects (a unique identifer).  Objects without this key will not be unique checked, additionally it does not affect non-`NSManagedObject` subclasses.

Example
=======
You can clone this repo and run the RestGoateeExample project, but you will need to run `pod install` in your installation directory.  (I am in the not-committing-your-pods camp).

We will use this example to turn a request to [iTunes Search API](https://itunes.apple.com/search?term=pink+floyd) into objects.
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
- (void) getResults:(NSString*)searchTerm completion:(RGResponseBlock)completion {
  /* your invocation of the API */
  [self GET:@"/search" parameters:@{ @"term" : searchTerm } keyPath:@"results" class:[RGBook class] completion:completion];
}
```

License
=======
BSD Simplied (2-clause)
