RestGoatee
==========

The non-boilerplate way to deserialize objects

Using this framework, Let's look at making a request to iTunes Search API.

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
{
  ...
  for (NSDictionary* dictionary in json) {
    ...
    RGBook* book = [RGBook objectFromJSON:dictionary]; //and that's it!
    ...
  }
  ...
}
```
