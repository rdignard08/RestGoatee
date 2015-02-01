
#import "RGXMLSerializer.h"
#import "RGXMLNode.h"

@interface RGXMLSerializer () <NSXMLParserDelegate>

@property (nonatomic, strong) RGXMLNode* rootNode;
@property (nonatomic, strong) RGXMLNode* currentNode;
@property (nonatomic, strong) NSMutableString* currentString;

@end

@implementation RGXMLSerializer

- (RGXMLNode*) rootNode {
    if (!_rootNode) {
        _rootNode = [RGXMLNode new];
    }
    return _rootNode;
}

- (RGXMLNode*) currentNode {
    if (!_currentNode) {
        _currentNode = self.rootNode;
    }
    return _currentNode;
}

- (NSMutableString*) currentString {
    if (!_currentString) {
        _currentString = [NSMutableString new];
    }
    return _currentString;
}

- (void) setParser:(NSXMLParser*)parser {
    parser.delegate = self;
    [parser parse];
}

- (id) body {
    return [self.rootNode asDictionary];
}

#pragma mark - NSXMLParserDelegate
- (void) parser:(__unused NSXMLParser*)p didStartElement:(NSString*)element namespaceURI:(__unused NSString*)n qualifiedName:(__unused NSString*)q attributes:(NSDictionary*)attributes {
    RGXMLNode* node = [RGXMLNode new];
    node.name = element;
    node.attributes = attributes;
    [self.currentNode addChildNode:node];
    self.currentNode = node;
}

- (void) parser:(__unused NSXMLParser*)p foundCharacters:(NSString*)string {
    [self.currentString appendString:string];
}

- (void) parser:(__unused NSXMLParser*)p didEndElement:(__unused NSString*)e namespaceURI:(__unused NSString*)n qualifiedName:(__unused NSString*)q {
    self.currentNode.text = self->_currentString;
    self.currentString = nil;
    self.currentNode = self.currentNode.parentNode; /* move up the parse tree */
}

- (void) parser:(__unused NSXMLParser*)p foundCDATA:(NSData*)CDATABlock {
    [self.currentString appendString:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}

@end
