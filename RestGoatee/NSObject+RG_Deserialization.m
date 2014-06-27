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

#define RG_PROPERTY_NAME @"name"
#define RG_PROPERTY_CANONICAL_NAME @"canonically"
#define RG_PROPERTY_STORAGE @"storage"
#define RG_PROPERTY_ATOMIC_TYPE @"atomicity"
#define RG_PROPERTY_ACCESS @"access"
#define RG_PROPERTY_BACKING @"ivar"
#define RG_PROPERTY_GETTER @"getter"
#define RG_PROPERTY_SETTER @"setter"
#define RG_PROPERTY_READWRITE @"readwrite"
#define RG_PROPERTY_READONLY @"readonly"
#define RG_PROPERTY_ASSIGN @"assign"
#define RG_PROPERTY_STRONG @"retain"
#define RG_PROPERTY_COPY @"copy"
#define RG_PROPERTY_WEAK @"weak"
#define RG_PROPERTY_CLASS @"type"
#define RG_PROPERTY_DYNAMIC @"__dynamic__"
#define RG_PROPERTY_ATOMIC @"atomic"
#define RG_PROPERTY_NONATOMIC @"nonatomic"

#define DATE_FORMAT_JAVASCRIPT @"yyyy-MM-dd'T'HH:mm:ssZZZZZ"
#define DATE_FORMAT_ERIC @"yyyy-MM-dd'T'HH:mm:ssz"
#define DATE_FORMAT_NSDATE @"yyyy-MM-dd HH:mm:ss ZZZZZ"
#define DATE_FORMAT_SIMPLE @"yyyy-MM-dd"

#define RG_SERIALIZATION_TYPE_KEY @"__class"

//RG_SERVER_TYPING /* Use this to turn on server driven type construction */
extern const NSString* classPrefix() WEAK_IMPORT_ATTRIBUTE;
extern const NSString* serverTypeKey() WEAK_IMPORT_ATTRIBUTE;
//const NSString* (*_pClassPrefix)(void) = classPrefix;
//const NSString* (*_pServerTypeKey)(void) = serverTypeKey;

NSString* trimLeadingAndTrailingQuotes(NSString*);
NSString* stringForTypeEncoding(NSString*);
NSDictionary* parsePropertyStruct(objc_property_t);
NSString* snakeCaseToCamelCase(NSString*);
NSString* canonicalForm(NSString*);

inline NSString* canonicalForm(NSString* input) {
    return [[[input componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""] uppercaseString];
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
                                           RG_PROPERTY_NAME : name,
                                           RG_PROPERTY_CANONICAL_NAME : canonicalForm(name),
                                           RG_PROPERTY_STORAGE : RG_PROPERTY_ASSIGN,
                                           RG_PROPERTY_ATOMIC_TYPE : RG_PROPERTY_ATOMIC,
                                           RG_PROPERTY_ACCESS : RG_PROPERTY_READWRITE } mutableCopy];
    /* Property attributes are exported as a raw char* separated by ',' */
    NSArray* attributes = [[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","];
    /* The first character is the type encoding; the remaining is a value of some kind (if anything)
     See: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html */
    for (NSString* attribute in attributes) {
        unichar heading = [attribute characterAtIndex:0];
        NSString* value = [attribute substringWithRange:NSMakeRange(1, attribute.length - 1)];
        switch (heading) {
            case '&':
                propertyDict[RG_PROPERTY_STORAGE] = RG_PROPERTY_STRONG;
                break;
            case 'C':
                propertyDict[RG_PROPERTY_STORAGE] = RG_PROPERTY_COPY;
                break;
            case 'W':
                propertyDict[RG_PROPERTY_STORAGE] = RG_PROPERTY_WEAK;
                break;
            case 'V':
                propertyDict[RG_PROPERTY_BACKING] = value;
                break;
            case 'D':
                propertyDict[RG_PROPERTY_BACKING] = RG_PROPERTY_DYNAMIC;
                break;
            case 'N':
                propertyDict[RG_PROPERTY_ATOMIC_TYPE] = RG_PROPERTY_NONATOMIC;
                break;
            case 'T':
                propertyDict[RG_PROPERTY_CLASS] = stringForTypeEncoding(value);
                break;
            case 't': /* TODO: I have no fucking idea what 'old-style' typing looks like */
                propertyDict[RG_PROPERTY_CLASS] = value;
                break;
            case 'R':
                propertyDict[RG_PROPERTY_ACCESS] = RG_PROPERTY_READONLY;
                break;
            case 'G':
                propertyDict[RG_PROPERTY_GETTER] = value;
                break;
            case 'S':
                propertyDict[RG_PROPERTY_SETTER] = value;
        }
    }
    return propertyDict;
}


@interface NSObject (RG_Introspection)

@property (nonatomic, strong, readonly) NSArray* __property_list__;

- (NSArray*) verbosePropertyList;
- (NSArray*) writableProperties;
- (NSString*) classStringForProperty:(NSString*)propertyName;

@end

@implementation NSObject (RG_Introspection)

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
        if ([property[RG_PROPERTY_ACCESS] isEqual:RG_PROPERTY_READWRITE]) {
            [ret addObject:property];
        }
    }
    return ret;
}

- (NSString*) classStringForProperty:(NSString*)propertyName {
    NSUInteger index = [self.__property_list__[RG_PROPERTY_NAME] indexOfObject:propertyName];
    return index == NSNotFound ? nil : self.__property_list__[index][RG_PROPERTY_CLASS];
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
#ifdef _COREDATADEFINES_H
    if ([self isSubclassOfClass:[NSManagedObject class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Managed object subclasses must be initialized within a managed object context.  Use +objectFromJSON:inContext:" userInfo:nil];
    }
#endif
    return [self objectFromJSON:json inContext:nil];
}

+ (instancetype) objectFromJSON:(NSDictionary*)json inContext:(id)context {
    NSObject* ret;
#ifdef _COREDATADEFINES_H
    if ([self isSubclassOfClass:[NSManagedObject class]]) {
        NSAssert(context, @"A subclass of NSManagedObject must be created within a valid NSManagedObjectContext.");
        ret = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:context];
    } else {
        ret = [[self alloc] init];
    }
#else
    ret = [[self alloc] init];
#endif
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
        if ((index = [propertiesToFill[RG_PROPERTY_CANONICAL_NAME] indexOfObject:canonicalForm(key)]) != NSNotFound) {
            @try {
                [ret initProperty:propertiesToFill[index][RG_PROPERTY_NAME] withJSONValue:json[key]];
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
    if ([self.__property_list__[RG_PROPERTY_NAME] indexOfObject:key] == NSNotFound) return;
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
                
                #ifdef RG_SERVER_TYPING
                if (&serverTypeKey != NULL && &classPrefix != NULL && serverTypeKey()) {
                    classString = [(classPrefix() ?: @"") stringByAppendingString:[obj[serverTypeKey()] capitalizedString]];
                } else
                #endif
                if (obj[RG_SERIALIZATION_TYPE_KEY]) {
                    classString = obj[RG_SERIALIZATION_TYPE_KEY];
                } else {
                    continue; /* can't parse this entry in the array */
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

- (NSDictionary*) dictionaryRepresentation {
    id ret;
    if (isInlineObject([self class])) {
        ret = [self description];
    } else if (isCollectionObject([self class])) {
        ret = [[NSMutableArray alloc] initWithCapacity:[(id)self count]];
        for (id object in (id)self) {
            [ret addObject:[object dictionaryRepresentation]];
        }
    } else if (isKeyedCollectionObject([self class])) {
        ret = [[NSMutableDictionary alloc] initWithCapacity:[(id)self count]];
        for (id key in (id)self) {
            ret[key] = self[key];
        }
        ret[RG_SERIALIZATION_TYPE_KEY] = NSStringFromClass([self class]);
    } else {
        ret = [[NSMutableDictionary alloc] initWithCapacity:self.__property_list__.count];
        for (NSDictionary* property in self.__property_list__) {
            if (self[property[RG_PROPERTY_NAME]]) {
                ret[property[RG_PROPERTY_NAME]] = self[property[RG_PROPERTY_NAME]];
            }
        }
        ret[RG_SERIALIZATION_TYPE_KEY] = NSStringFromClass([self class]);
    }
    
    return ret;
}

- (NSData*) JsonRepresentation {
    return [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:nil];
}

- (id) extendWith:(id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        object = [object dictionaryRepresentation];
    }
    for (NSString* propertyName in object) {
        [self initProperty:propertyName withJSONValue:object[propertyName]];
    }
    return self;
}

@end
