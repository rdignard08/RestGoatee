/* Copyright (c) 2/5/15, Ryan Dignard
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

/**
 This category is private, and methods defined therein are subject to change (moderately frequently).
 */
@implementation NSObject (RG_SerializationPrivate)

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

/**
 Is this property bad for serialization?
 */
+ (BOOL) rg_isPropertyToBeAvoided:(NSString*)propertyName {
    for (Class cls in [self rg_propertyListsToSkip]) {
        if ([self isSubclassOfClass:cls] && [cls rg_declarationForProperty:propertyName]) {
            return YES;
        }
    }
    return NO;
}

/**
 Is this property bad for serialization?
 */
- (BOOL) rg_isPropertyToBeAvoided:(NSString*)propertyName {
    return [[self class] rg_isPropertyToBeAvoided:propertyName];
}

/**
 Is this property a weak/assign object?
 */
+ (BOOL) rg_propertyIsWeak:(NSString*)propertyName {
    NSDictionary* declaration;
    if ((declaration = [self rg_declarationForProperty:propertyName])) {
        if (NSClassFromString(declaration[kRGPropertyRawType])) { /* primitives are assign, but we still want them */
            if (declaration[kRGPropertyStorage] == kRGPropertyWeak || declaration[kRGPropertyStorage] == kRGPropertyAssign) {
                return YES;
            }
        }
    }
    return NO;
}

/**
 Is this property a weak/assign object?
 */
- (BOOL) rg_propertyIsWeak:(NSString*)propertyName {
    return [[self class] rg_propertyIsWeak:propertyName];
}

/**
 This is called recursively to build up the response.
 */
- (id) rg_dictionaryHelper:(NSMutableArray*)pointersSeen followWeak:(BOOL)followWeak {
    if ([pointersSeen indexOfObject:self] != NSNotFound) return [NSNull null];
    /* [pointersSeen addObject:self]; // disable DAG for now */
    id ret;
    if (rg_isInlineObject([self class]) || rg_isClassObject(self)) { /* classes can be stored as strings too */
        ret = [self description];
    } else if (rg_isCollectionObject([self class])) {
        ret = [[NSMutableArray alloc] initWithCapacity:[(id)self count]];
        for (id object in (id)self) {
            [ret addObject:[object rg_dictionaryHelper:pointersSeen followWeak:followWeak]];
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
            if (followWeak || ![self rg_propertyIsWeak:propertyName]) {
                if (![self rg_isPropertyToBeAvoided:propertyName] && ![propertyName isEqual:kRGPropertyListProperty]) {
                    ret[propertyName] = [(self[propertyName] ?: [NSNull null]) rg_dictionaryHelper:pointersSeen followWeak:followWeak];
                }
            }
        }
        if (![[self class] isSubclassOfClass:[NSDictionary class]]) { /* only include the class key if the object _wasn't_ a dictionary */
            ret[kRGSerializationKey] = NSStringFromClass([self class]);
        }
    }
    return [ret copy];
}

@end

@implementation NSObject (RG_SerializationPublic)

- (NSDictionary*) dictionaryRepresentationShouldFollowWeakReferences:(BOOL)weakReferences {
    NSMutableArray* pointersSeen = [NSMutableArray array];
    return [self rg_dictionaryHelper:pointersSeen followWeak:weakReferences];
}

- (NSDictionary*) dictionaryRepresentation {
    return [self dictionaryRepresentationShouldFollowWeakReferences:YES];
}

- (NSData*) JSONRepresentation {
    return [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:nil];
}

@end
