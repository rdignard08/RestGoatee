/* Copyright (c) 6/10/14, Ryan Dignard
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#import "NSObject+RG_Deserialization.h"
#import <objc/runtime.h>

const NSString* const kRGPropertyName = @"name";
const NSString* const kRGPropertyCanonicalName = @"canonically";
const NSString* const kRGPropertyStorage = @"storage";
const NSString* const kRGPropertyAtomicType = @"atomicity";
const NSString* const kRGPropertyAccess = @"access";
const NSString* const kRGPropertyBacking = @"ivar";
const NSString* const kRGPropertyGetter = @"getter";
const NSString* const kRGPropertySetter = @"setter";
const NSString* const kRGPropertyReadwrite = @"readwrite";
const NSString* const kRGPropertyReadonly = @"readonly";
const NSString* const kRGPropertyAssign = @"assign";
const NSString* const kRGPropertyStrong = @"retain";
const NSString* const kRGPropertyCopy = @"copy";
const NSString* const kRGPropertyWeak = @"weak";
const NSString* const kRGPropertyClass = @"type";
const NSString* const kRGPropertyDynamic = @"__dynamic__";
const NSString* const kRGPropertyAtomic = @"atomic";
const NSString* const kRGPropertyNonatomic = @"nonatomic";

const NSString* const kRGSerializationKey = @"__class";
const NSString* const kRGPropertyListProperty = @"__property_list__";

#define DATE_FORMAT_JAVASCRIPT @"yyyy-MM-dd'T'HH:mm:ssZZZZZ"
#define DATE_FORMAT_ERIC @"yyyy-MM-dd'T'HH:mm:ssz"
#define DATE_FORMAT_NSDATE @"yyyy-MM-dd HH:mm:ss ZZZZZ"
#define DATE_FORMAT_SIMPLE @"yyyy-MM-dd"

const NSString* const (*_pClassPrefix)(void) = &classPrefix;
const NSString* const (*_pServerTypeKey)(void) = &serverTypeKey;

NSString* trimLeadingAndTrailingQuotes(NSString*);
NSString* stringForTypeEncoding(NSString*);
NSDictionary* parsePropertyStruct(objc_property_t);
NSString* snakeCaseToCamelCase(NSString*);
NSString* canonicalForm(NSString*);

NSString* canonicalForm(NSString* input) {
    NSString* output;
    size_t inputLength = input.length + 1; /* +1 for the char* nul terminator */
    char* inBuffer = calloc(inputLength, 1);
    [input getCString:inBuffer maxLength:inputLength encoding:NSUTF8StringEncoding];
    char* outBuffer = calloc(inputLength, 1);
    size_t i = 0, j = 0;
    for (; i != inputLength; i++) {
        char c = inBuffer[i];
        if (c > 47 && c < 58) { /* a digit; no change */
            outBuffer[j] = c;
            j++;
        } else if (c > 64 && c < 91) { /* an uppercase character; no change */
            outBuffer[j] = c;
            j++;
        } else if (c > 96 && c < 123) { /* a lowercase character; to upper */
            outBuffer[j] = c - 32;
            j++;
        } else {
            continue;
        }
    }
    output = [NSString stringWithUTF8String:outBuffer];
    free(inBuffer);
    free(outBuffer);
    return output;
}

NSString* snakeCaseToCamelCase(NSString* snakeString) {
    NSMutableString* ret = [NSMutableString string];
    NSArray* substrings = [snakeString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]];
    BOOL first = YES;
    for (__strong NSString* substring in substrings) {
        if (first) {
            first = NO;
        } else {
            substring = [substring capitalizedString];
        }
        [ret appendString:substring];
    }
    return ret;
}

static inline BOOL isInlineObject(Class cls) {
    return [cls isSubclassOfClass:[NSDate class]] || [cls isSubclassOfClass:[NSString class]] || [cls isSubclassOfClass:[NSData class]] || [cls isSubclassOfClass:[NSNumber class]] || [cls isSubclassOfClass:[NSNull class]] || [cls isSubclassOfClass:[NSValue class]];
}
static inline BOOL isCollectionObject(Class cls) {
    return [cls isSubclassOfClass:[NSSet class]] || [cls isSubclassOfClass:[NSArray class]] || [cls isSubclassOfClass:[NSOrderedSet class]];
}
static inline BOOL isKeyedCollectionObject(Class cls) {
    return [cls isSubclassOfClass:[NSDictionary class]];
}

NSString* trimLeadingAndTrailingQuotes(NSString* str) {
    NSArray* substrs = [str componentsSeparatedByString:@"\""];
    if (!substrs.count || substrs.count != 3) return str; /* there should be 2 '"' on each end, the class is in the middle, if not, give up */
    return substrs[1];
}

NSString* stringForTypeEncoding(NSString* str) {
    str = trimLeadingAndTrailingQuotes(str);
    return NSClassFromString(str) ? str : NSStringFromClass([NSNumber class]);
}

NSDictionary* parsePropertyStruct(objc_property_t property) {
    
    NSString* name = [NSString stringWithUTF8String:property_getName(property)];
    
    /* These are default values if there is no specification */
    NSMutableDictionary* propertyDict = [@{
                                           kRGPropertyName : name,
                                           kRGPropertyCanonicalName : canonicalForm(name),
                                           kRGPropertyStorage : kRGPropertyAssign,
                                           kRGPropertyAtomicType : kRGPropertyAtomic,
                                           kRGPropertyAccess : kRGPropertyReadwrite } mutableCopy];
    /* Property attributes are exported as a raw char* separated by ',' */
    NSArray* attributes = [[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","];
    /* The first character is the type encoding; the remaining is a value of some kind (if anything)
     See: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html */
    for (NSString* attribute in attributes) {
        unichar heading = [attribute characterAtIndex:0];
        NSString* value = [attribute substringWithRange:NSMakeRange(1, attribute.length - 1)];
        switch (heading) {
            case '&':
                propertyDict[kRGPropertyStorage] = kRGPropertyStrong;
                break;
            case 'C':
                propertyDict[kRGPropertyStorage] = kRGPropertyCopy;
                break;
            case 'W':
                propertyDict[kRGPropertyStorage] = kRGPropertyWeak;
                break;
            case 'V':
                propertyDict[kRGPropertyBacking] = value;
                break;
            case 'D':
                propertyDict[kRGPropertyBacking] = kRGPropertyDynamic;
                break;
            case 'N':
                propertyDict[kRGPropertyAtomicType] = kRGPropertyNonatomic;
                break;
            case 'T':
                propertyDict[kRGPropertyClass] = stringForTypeEncoding(value);
                break;
            case 't': /* TODO: I have no fucking idea what 'old-style' typing looks like */
                propertyDict[kRGPropertyClass] = value;
                break;
            case 'R':
                propertyDict[kRGPropertyAccess] = kRGPropertyReadonly;
                break;
            case 'G':
                propertyDict[kRGPropertyGetter] = value;
                break;
            case 'S':
                propertyDict[kRGPropertySetter] = value;
        }
    }
    return propertyDict;
}


@interface NSObject (RG_Introspection)

@property (nonatomic, strong, readonly) NSArray* __property_list__;

- (NSArray*) keys;
- (NSArray*) verbosePropertyList;
- (NSArray*) writableProperties;
- (NSString*) classStringForProperty:(NSString*)propertyName;

@end

@implementation NSObject (RG_Introspection)

/**
 @return a list of the keys/properties of the receiving object.
 */
- (NSArray*) keys {
    if ([self isKindOfClass:[NSDictionary class]]) {
        return [(id)self allKeys];
    }
    return self.__property_list__[kRGPropertyName];
}

+ (NSArray*) __property_list__ {
    id ret = objc_getAssociatedObject(self, _cmd);
    if(!ret) {
        ret = [self verbosePropertyList];
        objc_setAssociatedObject(self, _cmd, ret, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ret;
}

- (NSArray*) __property_list__ {
    return [[self class] __property_list__];
}

+ (NSArray*) classStack {
    NSMutableArray* stack = [NSMutableArray array];
    for (Class superClass = self; superClass; superClass = [superClass superclass]) {
        [stack addObject:superClass];
    }
    return stack;
}

- (NSArray*) verbosePropertyList {
    NSMutableArray* ret = [NSMutableArray array];
    NSMutableArray* stack = [[[self class] classStack] mutableCopy];
    for (Class cls = [stack lastObject]; cls; cls = [stack lastObject]) {
        objc_property_t* properties = class_copyPropertyList(cls, NULL);
        for (uint32_t i = 0; (properties + i) && properties[i]; i++) { /* While properties isn't NULL... */
            [ret addObject:parsePropertyStruct(properties[i])];
        }
        free(properties);
        [stack removeLastObject];
    }
    return ret;
}

- (NSArray*) writableProperties {
    NSMutableArray* ret = [NSMutableArray array];
    for (NSDictionary* property in self.__property_list__) {
        if (property[kRGPropertyAccess] == kRGPropertyReadwrite) {
            [ret addObject:property];
        }
    }
    return ret;
}

- (NSString*) classStringForProperty:(NSString*)propertyName {
    NSUInteger index = [self.__property_list__[kRGPropertyName] indexOfObject:propertyName];
    return index == NSNotFound ? nil : self.__property_list__[index][kRGPropertyClass];
}

@end

@implementation NSObject (RG_Deserialization)

- (id) objectForKeyedSubscript:(id<NSCopying, NSObject>)key {
    @try {
        return [self valueForKey:[key description]];
    }
    @catch (NSException* e) {
        return nil;
    }
}

- (void) setObject:(id)obj forKeyedSubscript:(id<NSCopying, NSObject>)key {
    @try {
        [self setValue:obj forKey:[key description]]; /* This is _intentionally_ not -setObject, -setValue is smarter; see the docs */
    }
    @catch (NSException* e) {}
}

+ (instancetype) objectFromJSON:(NSDictionary*)json {
    if ([self isSubclassOfClass:[NSClassFromString(@"NSManagedObject") class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Managed object subclasses must be initialized within a managed object context.  Use +objectFromJSON:inContext:" userInfo:nil];
    }
    return [self objectFromJSON:json inContext:nil];
}

+ (instancetype) objectFromJSON:(NSDictionary*)json inContext:(id)context {
    NSObject* ret;
    if ([self isSubclassOfClass:[NSClassFromString(@"NSManagedObject") class]]) {
        NSAssert(context, @"A subclass of NSManagedObject must be created within a valid NSManagedObjectContext.");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        ret = [NSClassFromString(@"NSEntityDescription") performSelector:@selector(insertNewObjectForEntityForName:inManagedObjectContext:) withObject:NSStringFromClass(self) withObject:context];
#pragma clang diagnostic pop
    } else {
        ret = [[self alloc] init];
    }
    NSArray* propertiesToFill = [ret __property_list__];
    NSMutableDictionary* overrides = [NSMutableDictionary dictionary];
    if ([(id)[ret class] respondsToSelector:@selector(overrideKeysForMapping)]) {
        [overrides addEntriesFromDictionary:[(id)[ret class] overrideKeysForMapping]];
    }
    if ([(id)ret respondsToSelector:@selector(overrideKeysForMapping)]) {
        [overrides addEntriesFromDictionary:[(id)ret overrideKeysForMapping]];
    }
    for (NSString* key in json) {
        /* default behavior self.key = json[key] (each `key` is compared in canonical form) */
        NSUInteger index;
        if ((index = [propertiesToFill[kRGPropertyCanonicalName] indexOfObject:canonicalForm(key)]) != NSNotFound) {
            @try {
                [ret initProperty:propertiesToFill[index][kRGPropertyName] withJSONValue:json[key]];
            }
            @catch (NSException* e) {} /* Should this fail the property is left alone */
        }
    }
    for (NSString* key in overrides) { /* The developer provided an override keypath */
        NSArray* keys = [key componentsSeparatedByString:@"."];
        id jsonValue = json;
        for (NSString* subkey in keys) {
            jsonValue = jsonValue[subkey];
        }
        @try {
            [ret initProperty:overrides[key] withJSONValue:jsonValue];
        }
        @catch (NSException* e) {} /* Should this fail the property is left alone */
    }
    return ret;
}

/**
 @abstract Coerces the JSONValue of the right-hand-side to match the type of the left-hand-side (rhs/lhs from this: self.property = jsonValue).
 
 @discussion JSON types when deserialized from NSData are: NSNull, NSNumber (number or boolean), NSString, NSArray, NSDictionary
 */
- (void) initProperty:(NSString*)key withJSONValue:(id)JSONValue {
    /* Can't initialize the value of a property if the property doesn't exist */
    if ([key isEqualToString:(NSString*)kRGPropertyListProperty]) return;
    if ([self.__property_list__[kRGPropertyName] indexOfObject:key] == NSNotFound) return;
    if (!JSONValue || [JSONValue isKindOfClass:[NSNull class]]) {
        /* We don't care what the receiving type is since it's empty anyway
        The docs say this may be a problem on primitive properties but I haven't observed this behavior when testing */
        self[key] = nil;
        return;
    }

    Class propertyType = NSClassFromString([self classStringForProperty:key]) ?: [NSNumber class]; /* NSClassFromString returns Nil when it can't parse the string; this corresponds to a primitive property */
    
    if ([JSONValue isKindOfClass:[NSArray class]]) { /* If the array we're given contains objects which we can create, create those too */
        uint32_t count = (uint32_t)[JSONValue count] ?: 1u;
        id parseBuffer[count];
        uint32_t idx = 0;
        for (id obj in JSONValue) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSString* classString;
                
                if (_pServerTypeKey != NULL && _pClassPrefix != NULL) {
                    const NSString* prefix = _pClassPrefix() ?: @"";
                    const NSString* typeKey = _pServerTypeKey() ?: @"";
                    const NSString* serverType = [obj[typeKey] capitalizedString] ?: @"";
                    classString = [prefix stringByAppendingString:(NSString*)serverType];
                } else if (!classString) {
                    if ([[obj keys] indexOfObject:kRGSerializationKey] != NSNotFound) {
                        classString = obj[kRGSerializationKey];
                    }
                }

                Class objectClass = NSClassFromString(classString);
                parseBuffer[idx] = objectClass ? [objectClass objectFromJSON:obj] : obj;
                idx++;
            }
        }
        JSONValue = [NSArray arrayWithObjects:parseBuffer count:idx];
    }
    
    if ([propertyType isSubclassOfClass:[JSONValue class]] && [JSONValue respondsToSelector:@selector(mutableCopyWithZone:)] && [[JSONValue mutableCopy] isMemberOfClass:propertyType]) {
        [self setValue:[JSONValue mutableCopy] forKey:key];
        return;
    } /* This is the one instance where we can quickly cast down the value */
    
    if ([JSONValue isKindOfClass:propertyType]) {
        [self setValue:JSONValue forKey:key];
        return;
    } /* If JSONValue is already a subclass of propertyType theres no reason to coerce it */
    
    /* Otherwise... this mess */
    
    if ([propertyType isSubclassOfClass:[NSDictionary class]]) { /* NSDictionary */
        self[key] = [[propertyType alloc] initWithDictionary:JSONValue];
    } else if (isCollectionObject(propertyType)) { /* NSArray, NSSet, or NSOrderedSet */
        self[key] = [[propertyType alloc] initWithArray:JSONValue];
    } else if ([propertyType isSubclassOfClass:[NSDecimalNumber class]]) { /* NSDecimalNumber, subclasses must go first */
        if ([JSONValue isKindOfClass:[NSNumber class]]) JSONValue = [JSONValue stringValue];
        [self setValue:[[NSDecimalNumber alloc] initWithString:JSONValue] forKey:key];
    } else if ([propertyType isSubclassOfClass:[NSNumber class]]) { /* NSNumber */
        if ([JSONValue isKindOfClass:[NSString class]]) JSONValue = @([JSONValue doubleValue]);
        [self setValue:[JSONValue copy] forKey:key]; /* Note: setValue: will unwrap the value if the destination is a primitive */
    } else if ([propertyType isSubclassOfClass:[NSString class]] || [propertyType isSubclassOfClass:[NSURL class]]) { /* NSString, NSURL */
        if ([JSONValue isKindOfClass:[NSArray class]]) JSONValue = [JSONValue componentsJoinedByString:@", "];
        if ([JSONValue isKindOfClass:[NSNumber class]]) JSONValue = [JSONValue stringValue];
        [self setValue:[[propertyType alloc] initWithString:JSONValue] forKey:key];
    } else if ([propertyType isSubclassOfClass:[NSDate class]]) { /* NSDate */
        NSString* providedDateFormat;
        if ([(id)[self class] respondsToSelector:@selector(dateFormatForKey:)]) {
            providedDateFormat = [(id)[self class] dateFormatForKey:key];
        }
        if ([self respondsToSelector:@selector(dateFormatForKey:)]) {
            providedDateFormat = [(id)self dateFormatForKey:key];
        }
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        NSDate* ret;
        if (providedDateFormat) {
            df.dateFormat = providedDateFormat;
            ret = [df dateFromString:JSONValue];
            if (ret) {
                self[key] = ret;
                return;
            }
        }
        for (NSString* dateFormat in @[DATE_FORMAT_JAVASCRIPT, DATE_FORMAT_NSDATE, DATE_FORMAT_ERIC, DATE_FORMAT_SIMPLE]) {
            df.dateFormat = dateFormat;
            ret = [df dateFromString:JSONValue];
            if (ret) break;
        }
        self[key] = ret;
        
    /* At this point we've exhausted the supported foundation classes for the LHS... these handle sub-objects */
    } else if ([JSONValue isKindOfClass:[NSDictionary class]]) { /* lhs is some kind of sub object, since the source has keys */
        self[key] = [propertyType objectFromJSON:JSONValue];
    } else if ([JSONValue isKindOfClass:[NSArray class]]) { /* single entry arrays are converted to an inplace object */
        id value = [JSONValue count] ? JSONValue[0] : nil;
        if (!value || [value isKindOfClass:propertyType]) {
            self[key] = value;
        }
    }
}

- (id) __dictionaryHelper:(NSMutableArray*)pointersSeen {
    if ([pointersSeen indexOfObject:self] != NSNotFound) return [NSNull null];
    /* [pointersSeen addObject:self]; // disable DAG for now */
    id ret;
    if (isInlineObject([self class])) {
        ret = [self description];
    } else if (isCollectionObject([self class])) {
        ret = [[NSMutableArray alloc] initWithCapacity:[(id)self count]];
        for (id object in (id)self) {
            [ret addObject:[object __dictionaryHelper:pointersSeen]];
        }
    } else if (isKeyedCollectionObject([self class])) {
        ret = [[NSMutableDictionary alloc] initWithCapacity:[(id)self count]];
        for (id key in (id)self) {
            ret[key] = self[key];
        }
        ret[kRGSerializationKey] = NSStringFromClass([self class]);
    } else {
        ret = [[NSMutableDictionary alloc] initWithCapacity:self.__property_list__.count];
        for (NSDictionary* property in self.__property_list__) {
            if (self[property[kRGPropertyName]]) {
                ret[property[kRGPropertyName]] = [self[property[kRGPropertyName]] __dictionaryHelper:pointersSeen];
            }
        }
        ret[kRGSerializationKey] = NSStringFromClass([self class]);
    }
    return ret;
}

- (NSDictionary*) dictionaryRepresentation {
    NSMutableArray* pointersSeen = [NSMutableArray array];
    return [self __dictionaryHelper:pointersSeen];
}

- (NSData*) JsonRepresentation {
    return [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:nil];
}

- (id) extendWith:(id)object {
    for (NSString* propertyName in [object keys]) {
        @try {
            [self initProperty:propertyName withJSONValue:object[propertyName]];
        }
        @catch (NSException* e) {}
    }
    return self;
}

@end
