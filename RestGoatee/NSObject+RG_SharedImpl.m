//
//  NSObject+RG_SharedImpl.m
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//
#import "NSObject+RG_SharedImpl.h"
#import <objc/runtime.h>
#import "RestGoatee.h"
#import <malloc/malloc.h>

/* Property Description Keys */
const NSString* const kRGPropertyAtomicType = @"atomicity";
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
const NSString* const kRGPropertyRawType = @"raw_type";
const NSString* const kRGPropertyDynamic = @"__dynamic__";
const NSString* const kRGPropertyAtomic = @"atomic";
const NSString* const kRGPropertyNonatomic = @"nonatomic";

/* Ivar Description Keys */
const NSString* const kRGIvarOffset = @"ivar_offset";
const NSString* const kRGIvarSize = @"ivar_size";
const NSString* const kRGIvarPrivate = @"private";
const NSString* const kRGIvarProtected = @"protected";
const NSString* const kRGIvarPublic = @"public";

/* Keys shared between properties and ivars */
const NSString* const kRGPropertyName = @"name";
const NSString* const kRGPropertyCanonicalName = @"canonically";
const NSString* const kRGPropertyStorage = @"storage";
const NSString* const kRGPropertyAccess = @"access";
const NSString* const kRGSerializationKey = @"__class";
const NSString* const kRGPropertyListProperty = @"__property_list__";

static const NSString* _sClassPrefix;
const NSString* const rg_classPrefix() {
    @synchronized ([NSObject class]) {
        if (!_sClassPrefix) {
            NSString* appDelegateName = [[[UIApplication sharedApplication].delegate class] description];
            for (NSUInteger i = 0; i < appDelegateName.length; i++) {
                unichar c = [appDelegateName characterAtIndex:i];
                if (c < 'A' || c > 'Z') { /* if it's not a capital letter, we've found the end of the prefix */
                    _sClassPrefix = [appDelegateName stringByReplacingCharactersInRange:NSMakeRange(i == 0 ?: i - 1, i == 0 ? appDelegateName.length : appDelegateName.length - i + 1) withString:@""]; /* the last capital character is not part of the prefix since it's the class name */
                    break;
                }
            }
            if (!_sClassPrefix) {
                _sClassPrefix = @""; /* In case nothing is found, we still want to return some string */
            }
        }
    }
    return _sClassPrefix;
}

void rg_setClassPrefix(const NSString* const prefix) {
    @synchronized ([NSObject class]) {
        _sClassPrefix = prefix;
    }
}

static const NSString* _sServerTypeKey;
void rg_setServerTypeKey(const NSString* const typeKey) {
    @synchronized ([NSObject class]) {
        _sServerTypeKey = typeKey;
    }
}

const NSString* const rg_serverTypeKey() {
    @synchronized ([NSObject class]) {
        return _sServerTypeKey;
    }
}

NSArray* const rg_dateFormats() {
    static dispatch_once_t onceToken;
    static NSArray* _sDateFormats;
    dispatch_once(&onceToken, ^{
        _sDateFormats = @[ @"yyyy-MM-dd'T'HH:mm:ssZZZZZ", @"yyyy-MM-dd HH:mm:ss ZZZZZ", @"yyyy-MM-dd'T'HH:mm:ssz", @"yyyy-MM-dd" ];
    });
    return _sDateFormats;
}

NSString* rg_canonicalForm(NSString* input) {
    NSString* output;
    const size_t inputLength = input.length + 1; /* +1 for the nul terminator */
    char* inBuffer, * outBuffer;
    inBuffer = malloc(inputLength << 1);
    outBuffer = inBuffer + inputLength;
    [input getCString:inBuffer maxLength:inputLength encoding:NSUTF8StringEncoding];
    size_t i = 0, j = 0;
    for (; i != inputLength; i++) {
        char c = inBuffer[i];
        if (c >= '0' && c <= '9') { /* a digit; no change */
            outBuffer[j++] = c;
        } else if (c >= 'A' && c <= 'Z') { /* an uppercase character; no change */
            outBuffer[j++] = c;
        } else if (c >= 'a' && c <= 'z') { /* a lowercase character; to upper */
            outBuffer[j++] = c - 32;
        } else {
            continue; /* unicodes, symbols, spaces, etc. are completely skipped */
        }
    }
    outBuffer[j] = '\0';
    output = [NSString stringWithUTF8String:outBuffer];
    free(inBuffer);
    return output;
}

BOOL rg_isClassObject(id object) {
    return ![object isKindOfClass:[NSObject class]] && object_getClass(/* the meta-class */object_getClass(object)) == object_getClass([NSObject class]);
    /* if the class of the meta-class == NSObject's meta-class; object was itself a Class object */
    /* object_getClass * object_getClass * <plain_nsobject> should not return true */
}

BOOL rg_isMetaClassObject(id object) {
    return rg_isClassObject(object) && object_getClass(object) == objc_getMetaClass("NSObject");
}

BOOL rg_isInlineObject(Class cls) {
    return [cls isSubclassOfClass:[NSDate class]] || [cls isSubclassOfClass:[NSString class]] || [cls isSubclassOfClass:[NSData class]] || [cls isSubclassOfClass:[NSNumber class]] || [cls isSubclassOfClass:[NSNull class]] || [cls isSubclassOfClass:[NSValue class]] || [cls isSubclassOfClass:[NSURL class]];
}

BOOL rg_isCollectionObject(Class cls) {
    return [cls isSubclassOfClass:[NSSet class]] || [cls isSubclassOfClass:[NSArray class]] || [cls isSubclassOfClass:[NSOrderedSet class]] || [cls isSubclassOfClass:[NSCountedSet class]];
}

BOOL rg_isKeyedCollectionObject(Class cls) {
    return [cls isSubclassOfClass:[NSDictionary class]];
}

NSString* rg_trimLeadingAndTrailingQuotes(NSString* str) {
    NSArray* substrs = [str componentsSeparatedByString:@"\""];
    if (substrs.count != 3) return str; /* there should be 2 '"' on each end, the class is in the middle, if not, give up */
    return substrs[1];
}

Class rg_classForTypeString(NSString* str) {
    if ([str isEqualToString:@"#"]) return objc_getMetaClass("NSObject");
    str = rg_trimLeadingAndTrailingQuotes(str);
    return NSClassFromString(str) ?: [NSNumber class];
}

void rg_parseIvarStructOntoPropertyDeclaration(Ivar ivar, NSMutableDictionary* propertyData) {
    propertyData[kRGIvarOffset] = @(ivar_getOffset(ivar));
}

NSMutableDictionary* rg_parseIvarStruct(Ivar ivar) {
    NSString* name = [NSString stringWithUTF8String:ivar_getName(ivar)];
    
    /* The default values for ivars are: assign (if primitive) strong (if object), protected */
    NSMutableDictionary* propertyDict = [@{
                                           kRGPropertyName : name,
                                           kRGPropertyCanonicalName : rg_canonicalForm(name),
                                           kRGPropertyStorage : kRGPropertyAssign,
                                           kRGPropertyAccess : kRGIvarProtected,
                                           kRGPropertyBacking : name,
                                           kRGIvarOffset : @(ivar_getOffset(ivar))
                                           } mutableCopy];
    NSString* ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
    propertyDict[kRGPropertyClass] = rg_classForTypeString(ivarType);
    propertyDict[kRGPropertyRawType] = rg_trimLeadingAndTrailingQuotes(ivarType);
    return propertyDict;
}

NSMutableDictionary* rg_parsePropertyStruct(objc_property_t property) {
    NSString* name = [NSString stringWithUTF8String:property_getName(property)];
    /* The default values for properties are: if object and ARC compiled: strong (we don't have to check for this, ARC will insert the retain attribute) else assign. atomic. readwrite. */
    NSMutableDictionary* propertyDict = [@{
                                           kRGPropertyName : name,
                                           kRGPropertyCanonicalName : rg_canonicalForm(name),
                                           kRGPropertyStorage : kRGPropertyAssign,
                                           kRGPropertyAtomicType : kRGPropertyAtomic,
                                           kRGPropertyAccess : kRGPropertyReadwrite } mutableCopy];
    uint32_t attributeCount = 0;
    objc_property_attribute_t* attributes = property_copyAttributeList(property, &attributeCount);
    for (uint32_t i = 0; i < attributeCount; i++) {
        objc_property_attribute_t attribute = attributes[i];
        unichar heading = strlen(attribute.name) ? attribute.name[0] : '\0';
        NSString* value = [NSString stringWithUTF8String:attribute.value];
        /* The first character is the type encoding; the other field is a value of some kind (if anything)
         See: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html */
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
            case 't': /* TODO: I have no fucking idea what 'old-style' typing looks like */
                propertyDict[kRGPropertyRawType] = rg_trimLeadingAndTrailingQuotes(value);
                propertyDict[kRGPropertyClass] = rg_classForTypeString(value);
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
    free(attributes);
    return propertyDict;
}

void rg_calculateIvarSize(Class object, NSMutableArray/*<NSMutableDictionary>*/* properties) {
    NSArray* rawOffsets = properties[kRGIvarOffset];
    NSMutableArray* offsets = [NSMutableArray new];
    for (NSUInteger i = 0; i < rawOffsets.count; i++) {
        NSNumber* offset = rawOffsets[i];
        if (![offset isKindOfClass:[NSNull class]]) {
            [offsets addObject:@{ @"o" : offset, @"i" : @(i) }];
        }
    }
    [offsets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[@"o"] compare:obj2[@"o"]];
    }];
    for (NSUInteger i = 0; i < offsets.count; i++) {
        NSDictionary* obj = offsets[i];
        NSNumber* nextOffset = (i == (offsets.count - 1)) ? @(class_getInstanceSize(object)) : offsets[i+1][@"o"];
        properties[[obj[@"i"] unsignedIntegerValue]][kRGIvarSize] = @([nextOffset unsignedIntegerValue] - [obj[@"o"] unsignedIntegerValue]);
    }
}

@implementation NSObject (RG_SharedImpl)

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

+ (NSArray*) __property_list__ {
    id ret = objc_getAssociatedObject(self, (__bridge const void*)kRGPropertyListProperty);
    if (!ret) {
        NSMutableArray* propertyStructure = [NSMutableArray array];
        NSMutableArray* stack = [NSMutableArray array];
        uint32_t count;
        for (Class superClass = self; superClass; superClass = [superClass superclass]) {
            [stack insertObject:superClass atIndex:0]; /* we want superclass properties to be overwritten by subclass properties so append front */
        }
        for (Class cls in stack) {
            objc_property_t* properties = class_copyPropertyList(cls, &count);
            for (uint32_t i = 0; i < count; i++) {
                [propertyStructure addObject:rg_parsePropertyStruct(properties[i])];
            }
            free(properties);
        }
        for (Class cls in stack) {
            Ivar* ivars = class_copyIvarList(cls, &count);
            for (uint32_t i = 0; i < count; i++) {
                NSString* ivarName = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
                NSUInteger ivarIndex = [propertyStructure[kRGPropertyBacking] indexOfObject:ivarName];
                if (ivarIndex == NSNotFound) {
                    [propertyStructure addObject:rg_parseIvarStruct(ivars[i])];
                } else {
                    rg_parseIvarStructOntoPropertyDeclaration(ivars[i], propertyStructure[ivarIndex]);
                }
            }
            free(ivars);
        }
        //rg_calculateIvarSize(self, propertyStructure);
        for (NSUInteger i = 0; i < propertyStructure.count; i++) {
            propertyStructure[i] = [propertyStructure[i] copy];
        }
        ret = [propertyStructure copy];
        objc_setAssociatedObject(self, (__bridge const void*)kRGPropertyListProperty, ret, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ret;
}

+ (NSDictionary*) rg_declarationForProperty:(NSString*)propertyName {
    NSUInteger index = [[self __property_list__][kRGPropertyName] indexOfObject:propertyName];
    return index == NSNotFound ? nil : [self __property_list__][index];
}

- (NSDictionary*) rg_declarationForProperty:(NSString*)propertyName {
    return [[self class] rg_declarationForProperty:propertyName];
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
    return [self rg_declarationForProperty:propertyName][kRGPropertyClass];
}

@end
