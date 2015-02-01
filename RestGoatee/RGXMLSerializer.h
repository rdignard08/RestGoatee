
#import <Foundation/Foundation.h>

@interface RGXMLSerializer : NSObject

/**
 Provide the NSXMLParser obtained from AFNetworking's AFXMLParserResponseSerializer
 */
@property (nonatomic, strong) NSXMLParser* parser;

- (id) body;

@end
