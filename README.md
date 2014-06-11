RestGoatee
==========

The non-boilerplate way to deserialize objects.

This framework has no dependencies beyond the objective-C runtime; it has support for CoreData which can be enabled by importing the CoreData header before (or within) RG_Deserialization.h

Example
=======
Using this framework, Let's look at turning a request to [iTunes Search API](https://itunes.apple.com/search?term=pink+floyd) into objects...
## Model Header

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

## Model Implementation

```objc
@implementation RGBook @end //nothing!
```

## In your API...

```
{ /* your callback when the API returns */
  //...
  for (NSDictionary* dictionary in json) {
    //...
    RGBook* book = [RGBook objectFromJSON:dictionary]; //and that's it!
    //...
  }
  //...
}
```
