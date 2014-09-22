//
//  NSObject+RG_Serialization.m
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//
#import "RestGoatee.h"
#import "NSObject+RG_SharedImpl.h"

@implementation NSObject (RG_Serialization)

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
    if (rg_isInlineObject([self class]) || rg_isClassObject(self)) { /* classes can be stored as strings too */
        ret = [self description];
    } else if (rg_isCollectionObject([self class])) {
        ret = [[NSMutableArray alloc] initWithCapacity:[(id)self count]];
        for (id object in (id)self) {
            [ret addObject:[object __dictionaryHelper:pointersSeen]];
        }
    } else if (rg_isKeyedCollectionObject([self class])) {
        ret = [[NSMutableDictionary alloc] initWithCapacity:[(id)self count]];
        for (id key in (id)self) {
            ret[key] = self[key];
        }
        ret[kRGSerializationKey] = NSStringFromClass([self class]);
    } else {
        ret = [[NSMutableDictionary alloc] initWithCapacity:self.__property_list__.count];
        for (NSDictionary* property in self.__property_list__) {
            NSString* propertyName = property[kRGPropertyName];
            if (![self rg_isPropertyToBeAvoided:propertyName] && ![propertyName isEqual:kRGPropertyListProperty]) {
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


@end
