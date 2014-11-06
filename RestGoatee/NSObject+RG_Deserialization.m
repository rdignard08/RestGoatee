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

NSArray* rg_unpackArray(NSArray* json, id context) {
    NSMutableArray* ret = [NSMutableArray array];
    for (__strong id obj in json) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            Class objectClass = NSClassFromString([rg_classPrefix() stringByAppendingString:([obj[rg_serverTypeKey()] capitalizedString] ?: @"")]);
            if (!objectClass) {
                objectClass = NSClassFromString(obj[kRGSerializationKey]);
            }
            obj = objectClass && ![objectClass isSubclassOfClass:[NSDictionary class]] ? [objectClass objectFromJSON:obj inContext:context] : obj;
        }
        [ret addObject:obj];
    }
    return [ret copy];
}

@implementation NSObject (RG_Deserialization)

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
    if ([key isKindOfClass:[NSNull class]] || [key isEqualToString:(NSString*)kRGPropertyListProperty] || ![self rg_declarationForProperty:key]) return;
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
    
    if (rg_isMetaClassObject(propertyType)) { /* the properties type is Meta-class so its a reference to Class */
        self[key] = NSClassFromString([JSONValue description]);
    } else if ([propertyType isSubclassOfClass:[NSDictionary class]]) { /* NSDictionary */
        self[key] = [[propertyType alloc] initWithDictionary:JSONValue];
    } else if (rg_isCollectionObject(propertyType)) { /* NSArray, NSSet, or NSOrderedSet */
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

- (instancetype) extendWith:(id)object inContext:(NSManagedObjectContext*)context {
    for (NSString* propertyName in [object rg_keys]) {
        if ([propertyName isEqual:(id)kRGPropertyListProperty]) continue;
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
