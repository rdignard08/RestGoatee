
#import <Foundation/Foundation.h>

@interface RGXMLNode : NSObject

@property (nonatomic, weak) RGXMLNode* parentNode;
@property (nonatomic, strong) NSDictionary* attributes;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* text;

- (void) addChildNode:(RGXMLNode*)node;
- (NSDictionary*) asDictionary;

@end
