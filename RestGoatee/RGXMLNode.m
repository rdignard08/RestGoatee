
#import "RGXMLNode.h"
#import "NSObject+RG_KeyedSubscripting.h"

const NSString* const kRGNameKey = @"__name__";
const NSString* const kRGTextContentKey = @"__text__";
const NSString* const kRGChildNodesKey = @"__child_nodes__";

@interface RGXMLNode ()

@property (nonatomic, strong) NSMutableArray* childNodes;

@end

@implementation RGXMLNode

- (NSMutableArray*) childNodes {
    if (!_childNodes) {
        _childNodes = [NSMutableArray new];
    }
    return _childNodes;
}

- (void) addChildNode:(RGXMLNode*)node {
    node.parentNode = self;
    [self.childNodes addObject:node];
}

- (NSMutableDictionary*) asDictionary {
    const static NSString* propertyNameKey = @"name";
    NSMutableDictionary* ret = [NSMutableDictionary dictionaryWithDictionary:self.attributes];
    
    if (self.text) ret[kRGTextContentKey] = self.text;
    if (self.name) ret[kRGNameKey] = self.name;
    
    BOOL needsArray = NO;
    NSArray* childrensNames = self.childNodes[propertyNameKey];
    for (NSUInteger i = 0; i < childrensNames.count; i++) {
        NSString* name = childrensNames[i];
        NSInteger index = [childrensNames indexOfObject:name inRange:NSMakeRange(i + 1, childrensNames.count - i - 1)];
        NSInteger dictionaryIndex = [[ret allKeys] indexOfObject:name];
        if (index != NSNotFound || dictionaryIndex != NSNotFound) {
            needsArray = YES;
        }
    }
    
    if (needsArray) {
        NSMutableArray* array = [NSMutableArray new];
        for (RGXMLNode* node in self.childNodes) {
            [array addObject:[node asDictionary:ret]];
        }
        if (array.count) ret[kRGChildNodesKey] = array.count == 1 ? [array firstObject] : array;
    } else {
        for (RGXMLNode* node in self.childNodes) {
            ret[node.name] = [node asDictionary:ret];
        }
    }

    return ret;
}

- (NSDictionary*) asDictionary:(NSMutableDictionary*)inDict {
    NSDictionary* ret = [self asDictionary];
    
    if (ret.count == 2 && ret[kRGTextContentKey] && ret[kRGNameKey]) { /* this entry can be inlined */
        if (!inDict[ret[kRGNameKey]]) {
            return ret[kRGTextContentKey];
        }
    }
    
    if (ret[kRGChildNodesKey]) { /* the presence of the kRGChildNodesKey key indicates this needs to be elided */
        return ret[kRGChildNodesKey];
    }
    
    return ret;
}

@end
