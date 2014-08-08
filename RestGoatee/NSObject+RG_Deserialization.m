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

static NSString* rg_trimLeadingAndTrailingQuotes(NSString*) __attribute__((pure));
static Class rg_classForTypeString(NSString*) __attribute__((pure));
static NSDictionary* rg_parsePropertyStruct(objc_property_t) __attribute__((pure));
static NSString* rg_canonicalForm(NSString*) __attribute__((pure));

#ifndef __SERVER_TYPING_
const NSString* const classPrefix() {
    return nil;
}

const NSString* const serverTypeKey() {
    return nil;
}
#endif

static NSArray* const rg_dateFormats() {
    static dispatch_once_t onceToken;
    static NSArray* _sDateFormats;
    dispatch_once(&onceToken, ^{
        _sDateFormats = @[ @"yyyy-MM-dd'T'HH:mm:ssZZZZZ", @"yyyy-MM-dd HH:mm:ss ZZZZZ", @"yyyy-MM-dd'T'HH:mm:ssz", @"yyyy-MM-dd" ];
    });
    return _sDateFormats;
}

static NSString* rg_canonicalForm(NSString* input) {
    NSString* output;
    const size_t inputLength = input.length + 1; /* +1 for the nul terminator */
    char* inBuffer, * outBuffer;
    inBuffer = malloc(inputLength << 1);
    outBuffer = inBuffer + inputLength;
    [input getCString:inBuffer maxLength:inputLength encoding:NSUTF8StringEncoding];
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
            continue; /* unicodes, symbols, spaces, etc. are completely skipped */
        }
    }
    outBuffer[j] = '\0';
    output = [NSString stringWithUTF8String:outBuffer];
    free(inBuffer);
    return output;
}

static NSArray* rg_unpackArray(NSArray* json, id context) {
    NSMutableArray* ret = [NSMutableArray array];
    for (__strong id obj in json) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            Class objectClass = NSClassFromString([(classPrefix() ?: @"") stringByAppendingString:([obj[serverTypeKey()] capitalizedString] ?: @"")]);
            if (!objectClass) {
                objectClass = NSClassFromString(obj[kRGSerializationKey]);
            }
            obj = objectClass && ![objectClass isSubclassOfClass:[NSDictionary class]] ? [objectClass objectFromJSON:obj inContext:context] : obj;
        }
        [ret addObject:obj];
    }
    return [ret copy];
}

static inline BOOL isClassObject(id object) {
    return object_getClass(/* the meta-class */object_getClass(object)) == object_getClass([NSObject class]);
    /* if the class of the meta-class == NSObject's meta-class; object was itself a Class object */
}

static inline BOOL isMetaClassObject(id object) {
    return isClassObject(object) && object_getClass(object) == objc_getMetaClass("NSObject");
}

static inline BOOL isInlineObject(Class cls) {
    return [cls isSubclassOfClass:[NSDate class]] || [cls isSubclassOfClass:[NSString class]] || [cls isSubclassOfClass:[NSData class]] || [cls isSubclassOfClass:[NSNumber class]] || [cls isSubclassOfClass:[NSNull class]] || [cls isSubclassOfClass:[NSValue class]];
}
static inline BOOL isCollectionObject(Class cls) {
    return [cls isSubclassOfClass:[NSSet class]] || [cls isSubclassOfClass:[NSArray class]] || [cls isSubclassOfClass:[NSOrderedSet class]] || [cls isSubclassOfClass:[NSCountedSet class]];
}
static inline BOOL isKeyedCollectionObject(Class cls) {
    return [cls isSubclassOfClass:[NSDictionary class]];
}

static NSString* rg_trimLeadingAndTrailingQuotes(NSString* str) {
    NSArray* substrs = [str componentsSeparatedByString:@"\""];
    if (substrs.count != 3) return str; /* there should be 2 '"' on each end, the class is in the middle, if not, give up */
    return substrs[1];
}

static Class rg_classForTypeString(NSString* str) {
    if ([str isEqualToString:@"#"]) return objc_getMetaClass("NSObject");
    str = rg_trimLeadingAndTrailingQuotes(str);
    return NSClassFromString(str) ?: [NSNumber class];
}

static NSDictionary* rg_parsePropertyStruct(objc_property_t property) {
    
    NSString* name = [NSString stringWithUTF8String:property_getName(property)];
    
    /* These are default values if there is no specification */
    NSMutableDictionary* propertyDict = [@{
                                           kRGPropertyName : name,
                                           kRGPropertyCanonicalName : rg_canonicalForm(name),
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
                propertyDict[kRGPropertyClass] = rg_classForTypeString(value);
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

- (NSArray*) __property_list__;
- (NSArray*) rg_keys;
- (Class) rg_classForProperty:(NSString*)propertyName;

@end

@implementation NSObject (RG_Introspection)

+ (NSArray*) __property_list__ {
    id ret = objc_getAssociatedObject(self, (__bridge const void*)kRGPropertyListProperty);
    if (!ret) {
        NSMutableArray* propertyStructure = [NSMutableArray array];
        NSMutableArray* stack = [NSMutableArray array];
        for (Class superClass = self; superClass; superClass = [superClass superclass]) {
            [stack insertObject:superClass atIndex:0]; /* we want superclass properties to be overwritten by subclass properties so append front */
        }
        for (Class cls in stack) {
            objc_property_t* properties = class_copyPropertyList(cls, NULL);
            for (uint32_t i = 0; (properties + i) && properties[i]; i++) {
                [propertyStructure addObject:rg_parsePropertyStruct(properties[i])];
            }
            free(properties);
        }
        ret = [propertyStructure copy];
        objc_setAssociatedObject(self, (__bridge const void*)kRGPropertyListProperty, ret, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ret;
}

- (NSArray*) __property_list__ {
    return [[self class] __property_list__];
}

/**
 @return a list of the keys/properties of the receiving object.
 */
- (NSArray*) rg_keys {
    if ([self isKindOfClass:[NSDictionary class]]) {
        return [(id)self allKeys];
    }
    return self.__property_list__[kRGPropertyName];
}

- (Class) rg_classForProperty:(NSString*)propertyName {
    NSUInteger index = [self.__property_list__[kRGPropertyName] indexOfObject:propertyName];
    return index == NSNotFound ? nil : self.__property_list__[index][kRGPropertyClass];
}

@end

@implementation NSObject (RG_Deserialization)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rg_sNSManagedObjectContext = NSClassFromString(@"NSManagedObjectContext");
        rg_sNSManagedObject = NSClassFromString(@"NSManagedObject");
        rg_sNSManagedObjectModel = NSClassFromString(@"NSManagedObjectModel");
        rg_sNSPersistentStoreCoordinator = NSClassFromString(@"NSPersistentStoreCoordinator");
        rg_sNSEntityDescription = NSClassFromString(@"NSEntityDescription");
        rg_sNSFetchRequest = NSClassFromString(@"NSFetchRequest");
    });
}

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
    if ([self isSubclassOfClass:[rg_sNSManagedObject class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Managed object subclasses must be initialized within a managed object context.  Use +objectFromJSON:inContext:" userInfo:nil];
    }
    return [self objectFromJSON:json inContext:nil];
}

+ (instancetype) objectFromJSON:(NSDictionary*)json inContext:(id)context {
    NSObject* ret;
    if ([self isSubclassOfClass:[rg_sNSManagedObject class]]) {
        NSAssert(context, @"A subclass of NSManagedObject must be created within a valid NSManagedObjectContext.");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        ret = [rg_sNSEntityDescription performSelector:@selector(insertNewObjectForEntityForName:inManagedObjectContext:) withObject:NSStringFromClass(self) withObject:context];
#pragma clang diagnostic pop
    } else {
        ret = [[self alloc] init];
    }
    NSArray* propertiesToFill = [ret __property_list__];
    NSMutableDictionary* overrides = [NSMutableDictionary dictionary];
    if ([(id)[ret class] respondsToSelector:@selector(overrideKeysForMapping)]) {
        [overrides addEntriesFromDictionary:[(id)[ret class] overrideKeysForMapping]];
    }
    if ([ret respondsToSelector:@selector(overrideKeysForMapping)]) {
        [overrides addEntriesFromDictionary:[(id)ret overrideKeysForMapping]];
    }
    for (NSString* key in json) {
        /* default behavior self.key = json[key] (each `key` is compared in canonical form) */
        NSUInteger index;
        if ((index = [propertiesToFill[kRGPropertyCanonicalName] indexOfObject:rg_canonicalForm(key)]) != NSNotFound) {
            @try {
                [ret rg_initProperty:propertiesToFill[index][kRGPropertyName] withJSONValue:json[key] inContext:context];
            }
            @catch (NSException* e) {} /* Should this fail the property is left alone */
        }
    }
    for (NSString* key in overrides) { /* The developer provided an override keypath */
        id jsonValue = [json valueForKeyPath:key];
        @try {
            [ret rg_initProperty:overrides[key] withJSONValue:jsonValue inContext:context];
        }
        @catch (NSException* e) {} /* Should this fail the property is left alone */
    }
    return ret;
}

/**
 @abstract Coerces the JSONValue of the right-hand-side to match the type of the left-hand-side (rhs/lhs from this: self.property = jsonValue).
 
 @discussion JSON types when deserialized from NSData are: NSNull, NSNumber (number or boolean), NSString, NSArray, NSDictionary
 */
- (void) rg_initProperty:(NSString*)key withJSONValue:(id)JSONValue inContext:(NSManagedObjectContext*)context {
    /* Can't initialize the value of a property if the property doesn't exist */
    if ([key isKindOfClass:[NSNull class]] || [key isEqualToString:(NSString*)kRGPropertyListProperty] || [self.__property_list__[kRGPropertyName] indexOfObject:key] == NSNotFound) return;
    if (!JSONValue || [JSONValue isKindOfClass:[NSNull class]]) {
        /* We don't care what the receiving type is since it's empty anyway
        The docs say this may be a problem on primitive properties but I haven't observed this behavior when testing */
        self[key] = nil;
        return;
    }

    Class propertyType = [self rg_classForProperty:key];
    
    if ([JSONValue isKindOfClass:[NSArray class]]) { /* If the array we're given contains objects which we can create, create those too */
        JSONValue = rg_unpackArray(JSONValue, context);
    }
    
    if ([JSONValue respondsToSelector:@selector(mutableCopyWithZone:)] && [[JSONValue mutableCopy] isMemberOfClass:propertyType]) {
        [self setValue:[JSONValue mutableCopy] forKey:key];
        return;
    } /* This is the one instance where we can quickly cast down the value */
    
    if ([JSONValue isKindOfClass:propertyType]) {
        [self setValue:JSONValue forKey:key];
        return;
    } /* If JSONValue is already a subclass of propertyType theres no reason to coerce it */
    
    /* Otherwise... this mess */
    
    if (isMetaClassObject(propertyType)) { /* the properties type is Meta-class so its a reference to Class */
        self[key] = NSClassFromString([JSONValue description]);
    } else if ([propertyType isSubclassOfClass:[NSDictionary class]]) { /* NSDictionary */
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
        for (NSString* dateFormat in rg_dateFormats()) {
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

/** Certain classes are too difficult to serialize in a straight-forward manner, so we skip the properties on those classes.  Pretty much any class with cyclical references is gonna suck. */
+ (NSArray*) rg_propertyListsToSkip {
    static NSArray* _classes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _classes = @[
                    [NSObject class],
                    rg_sNSManagedObject ?: [NSNull class],
                    rg_sNSManagedObjectContext ?: [NSNull class],
                    rg_sNSManagedObjectModel ?: [NSNull class],
                    rg_sNSPersistentStoreCoordinator ?: [NSNull class],
                ];
    });
    return _classes;
}

+ (BOOL) rg_isPropertyToBeAvoided:(NSString*)propertyName {
    for (Class cls in [self rg_propertyListsToSkip]) {
        if ([self isSubclassOfClass:cls]) {
            if ([[cls __property_list__][kRGPropertyName] indexOfObject:propertyName] != NSNotFound) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL) rg_isPropertyToBeAvoided:(NSString*)propertyName {
    return [[self class] rg_isPropertyToBeAvoided:propertyName];
}

- (id) __dictionaryHelper:(NSMutableArray*)pointersSeen {
    if ([pointersSeen indexOfObject:self] != NSNotFound) return [NSNull null];
    /* [pointersSeen addObject:self]; // disable DAG for now */
    id ret;
    if (isInlineObject([self class]) || isClassObject(self)) {
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
            NSString* propertyName = property[kRGPropertyName];
            if (![ret rg_isPropertyToBeAvoided:propertyName] && ![propertyName isEqual:kRGPropertyListProperty]) {
                ret[propertyName] = [(self[propertyName] ?: [NSNull null]) __dictionaryHelper:pointersSeen];
            }
        }
        if (![[self class] isSubclassOfClass:[NSDictionary class]]) { /* only include the class key if the object _wasn't_ a dictionary */
            ret[kRGSerializationKey] = NSStringFromClass([self class]);
        }
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

- (instancetype) extendWith:(id)object inContext:(NSManagedObjectContext*)context {
    for (NSString* propertyName in [object rg_keys]) {
        if ([propertyName isEqualToString:(NSString*)kRGPropertyListProperty]) continue;
        @try {
            [self rg_initProperty:propertyName withJSONValue:object[propertyName] inContext:context];
        }
        @catch (NSException* e) {}
    }
    return self;
}

- (instancetype) extendWith:(id)object {
    return [self extendWith:object inContext:nil];
}

@end
