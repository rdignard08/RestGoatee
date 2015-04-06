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
#import "RestGoatee.h"
#import "NSObject+RG_SharedImpl.h"

@interface NSObject (RGForwardDeclarations)
+ (id) insertNewObjectForEntityForName:(NSString*)entityName inManagedObjectContext:(id)context;
@end

NSArray* rg_unpackArray(NSArray* json, id context) {
    NSMutableArray* ret = [NSMutableArray array];
    for (__strong id obj in json) {
        if ([obj conformsToProtocol:@protocol(RGDataSourceProtocol)]) {
            Class objectClass = NSClassFromString([rg_classPrefix() stringByAppendingString:([obj[rg_serverTypeKey()] capitalizedString] ?: @"")]) ?: NSClassFromString(obj[kRGSerializationKey]);
            obj = [objectClass conformsToProtocol:@protocol(RGDataSourceProtocol)] ? obj : [objectClass objectFromDataSource:obj inContext:context];
        }
        [ret addObject:obj];
    }
    return [ret copy];
}

@implementation NSObject (RG_Deserialization)

+ (instancetype) objectFromDataSource:(id<RGDataSourceProtocol>)source {
    if ([self isSubclassOfClass:rg_sNSManagedObject]) {
        [NSException raise:NSGenericException format:@"Managed object subclasses must be initialized within a managed object context.  Use +objectFromJSON:inContext:"];
    }
    return [self objectFromDataSource:source inContext:nil];
}

+ (instancetype) objectFromDataSource:(id<RGDataSourceProtocol>)source inContext:(id)context {
    NSObject* ret;
    if ([self isSubclassOfClass:rg_sNSManagedObject]) {
        context ?: [NSException raise:NSGenericException format:@"A subclass of NSManagedObject must be created within a valid NSManagedObjectContext."];
        DO_RISKY_BUSINESS
        ret = [rg_sNSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:context];
        END_RISKY_BUSINESS
    } else {
        ret = [self new];
    }
    NSArray* propertiesToFill = [ret __property_list__];
    NSMutableDictionary* overrides = [NSMutableDictionary dictionary];
    if ([(id)[ret class] respondsToSelector:@selector(overrideKeysForMapping)]) {
        [overrides addEntriesFromDictionary:[(id)[ret class] overrideKeysForMapping]];
    }
    if ([ret respondsToSelector:@selector(overrideKeysForMapping)]) {
        [overrides addEntriesFromDictionary:[(id)ret overrideKeysForMapping]];
    }
    for (NSString* key in source) {
        /* default behavior self.key = json[key] (each `key` is compared in canonical form) */
        if (overrides[key]) continue;
        NSUInteger index;
        if ((index = [propertiesToFill[kRGPropertyCanonicalName] indexOfObject:rg_canonicalForm(key)]) != NSNotFound) {
            @try {
                [ret rg_initProperty:propertiesToFill[index][kRGPropertyName] withValue:source[key] inContext:context];
            }
            @catch (NSException* e) { /* Should this fail the property is left alone */
                RGLog(@"initializing property %@ on type %@ failed: %@", propertiesToFill[index][kRGPropertyName], [ret class], e);
            }
        }
    }
    for (NSString* key in overrides) { /* The developer provided an override keypath */
        id value = [source valueForKeyPath:key];
        @try {
            [ret rg_initProperty:overrides[key] withValue:value inContext:context];
        }
        @catch (NSException* e) { /* Should this fail the property is left alone */
            RGLog(@"initializing property %@ on type %@ failed: %@", overrides[key], [ret class], e);
        }
    }
    return ret;
}

/**
 @abstract Coerces the JSONValue of the right-hand-side to match the type of the left-hand-side (rhs/lhs from this: self.property = jsonValue).
 
 @discussion JSON types when deserialized from NSData are: NSNull, NSNumber (number or boolean), NSString, NSArray, NSDictionary
 */
- (void) rg_initProperty:(NSString*)key withValue:(id)value inContext:(id)context {
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
    });
    
    /* Can't initialize the value of a property if the property doesn't exist */
    if ([key isKindOfClass:[NSNull class]] || [key isEqual:kRGPropertyListProperty] || ![self rg_declarationForProperty:key]) {
        return;
    }
    
    if (!value || [value isKindOfClass:[NSNull class]]) {
        /* We don't care what the receiving type is since it's empty anyway. The docs say this may be a problem on primitive properties but I haven't observed this behavior when testing */
        self[key] = nil;
        return;
    }

    Class propertyType = [self rg_classForProperty:key];
    
    if ([value isKindOfClass:[NSArray class]]) { /* If the array we're given contains objects which we can create, create those too */
        value = rg_unpackArray(value, context);
    }
    
    id mutableVersion = [value respondsToSelector:@selector(mutableCopyWithZone:)] ? [value mutableCopy] : nil;
    if ([mutableVersion isMemberOfClass:propertyType]) { /* if the target is a mutable of a immutable type we already have */
        self[key] = mutableVersion;
        return;
    } /* This is the one instance where we can quickly cast down the value */
    
    if ([value isKindOfClass:propertyType]) { /* NSValue */
        self[key] = value;
        return;
    } /* If JSONValue is already a subclass of propertyType theres no reason to coerce it */
    
    /* Otherwise... this mess */
    
    if (rg_isMetaClassObject(propertyType)) { /* the properties type is Meta-class so its a reference to Class */
        self[key] = NSClassFromString([value description]);
    } else if ([propertyType isSubclassOfClass:[NSDictionary class]]) { /* NSDictionary */
        self[key] = [[propertyType alloc] initWithDictionary:value];
    } else if (rg_isCollectionObject(propertyType)) { /* NSArray, NSSet, or NSOrderedSet */
        self[key] = [[propertyType alloc] initWithArray:value];
    } else if ([propertyType isSubclassOfClass:[NSDecimalNumber class]]) { /* NSDecimalNumber, subclasses must go first */
        if ([value isKindOfClass:[RGXMLNode class]]) value = [value innerXML];
        if ([value isKindOfClass:[NSNumber class]]) value = [value stringValue];
        self[key] = [propertyType decimalNumberWithString:value];
    } else if ([propertyType isSubclassOfClass:[NSNumber class]]) { /* NSNumber */
        if ([value isKindOfClass:[RGXMLNode class]]) value = [value innerXML];
        if ([value isKindOfClass:[NSString class]]) value = @([value doubleValue]);
        self[key] = value; /* Note: setValue: will unwrap the value if the destination is a primitive */
    } else if ([propertyType isSubclassOfClass:[NSString class]] || [propertyType isSubclassOfClass:[NSURL class]]) { /* NSString, NSURL */
        if ([value isKindOfClass:[RGXMLNode class]]) value = [value innerXML];
        if ([value isKindOfClass:[NSArray class]]) value = [value componentsJoinedByString:@", "];
        if ([value isKindOfClass:[NSNumber class]]) value = [value stringValue];
        self[key] = [[propertyType alloc] initWithString:value];
    } else if ([propertyType isSubclassOfClass:[NSDate class]]) { /* NSDate */
        if ([value isKindOfClass:[RGXMLNode class]]) value = [value innerXML];
        NSString* providedDateFormat;
        if ([[self class] respondsToSelector:@selector(dateFormatForKey:)]) {
            providedDateFormat = [[self class] dateFormatForKey:key];
        }
        if ([self respondsToSelector:@selector(dateFormatForKey:)]) {
            providedDateFormat = [(id)self dateFormatForKey:key];
        }
        if (providedDateFormat) {
            dateFormatter.dateFormat = providedDateFormat;
            self[key] = [dateFormatter dateFromString:value];
            return; /* Let's not second-guess the developer... */
        } else {
            for (NSString* dateFormat in rg_dateFormats()) {
                dateFormatter.dateFormat = dateFormat;
                self[key] = [dateFormatter dateFromString:value];
                if (self[key]) break;
            }
        }
        
    /* At this point we've exhausted the supported foundation classes for the LHS... these handle sub-objects */
    } else if ([value conformsToProtocol:@protocol(RGDataSourceProtocol)]) { /* lhs is some kind of user defined object, since the source has keys, but doesn't match NSDictionary */
        self[key] = [propertyType objectFromDataSource:value inContext:context];
    } else if ([value isKindOfClass:[NSArray class]]) { /* single entry arrays are converted to an inplace object */
        [value count] > 1 ? RGLog(@"Warning, data loss on property %@ on type %@", key, [self class]) : nil;
        id firstValue = [value firstObject];
        if (!firstValue || [firstValue isKindOfClass:propertyType]) {
            self[key] = value;
        }
    }
    
    self[key] ?: RGLog(@"Warning, initialization failed on property %@ on type %@", key, [self class]);
}

- (instancetype) extendWith:(id)object inContext:(id)context {
    for (NSString* propertyName in [object rg_keys]) {
        if (topClassDeclaringPropertyNamed([self class], propertyName) != [NSObject class]) {
            @try {
                [self rg_initProperty:propertyName withValue:object[propertyName] inContext:context];
            }
            @catch (NSException* e) {
                RGLog(@"Warning, exception initializing property %@ on type %@: %@", propertyName, [object class], e);
            }
        }
    }
    return self;
}

- (instancetype) extendWith:(id)object {
    return [self extendWith:object inContext:nil];
}

@end
