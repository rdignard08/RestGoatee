//  NSObject+RG_SharedImpl.h
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.

struct objc_property;

extern const NSString* const kRGPropertyName;
extern const NSString* const kRGPropertyCanonicalName;
extern const NSString* const kRGPropertyStorage;
extern const NSString* const kRGPropertyAtomicType;
extern const NSString* const kRGPropertyAccess;
extern const NSString* const kRGPropertyBacking;
extern const NSString* const kRGPropertyGetter;
extern const NSString* const kRGPropertySetter;
extern const NSString* const kRGPropertyReadwrite;
extern const NSString* const kRGPropertyReadonly;
extern const NSString* const kRGPropertyAssign;
extern const NSString* const kRGPropertyStrong;
extern const NSString* const kRGPropertyCopy;
extern const NSString* const kRGPropertyWeak;
extern const NSString* const kRGPropertyClass;
extern const NSString* const kRGPropertyRawType;
extern const NSString* const kRGPropertyDynamic;
extern const NSString* const kRGPropertyAtomic;
extern const NSString* const kRGPropertyNonatomic;
extern const NSString* const kRGSerializationKey;
extern const NSString* const kRGPropertyListProperty;

/**
 These classes are used to dynamically link into coredata if present.
 */
Class rg_sNSManagedObjectContext;
Class rg_sNSManagedObject;
Class rg_sNSManagedObjectModel;
Class rg_sNSPersistentStoreCoordinator;
Class rg_sNSEntityDescription;
Class rg_sNSFetchRequest;

NSArray* const rg_dateFormats();
NSString* rg_canonicalForm(NSString* input);
BOOL rg_isClassObject(id object);
BOOL rg_isMetaClassObject(id object);
BOOL rg_isInlineObject(Class cls);
BOOL rg_isCollectionObject(Class cls);
BOOL rg_isKeyedCollectionObject(Class cls);
Class rg_classForTypeString(NSString* str);
NSDictionary* rg_parsePropertyStruct(struct objc_property* property);
NSString* rg_trimLeadingAndTrailingQuotes(NSString* str);

@interface NSObject (RG_SharedImpl)

- (NSArray*) __property_list__;
- (NSArray*) rg_keys;
- (Class) rg_classForProperty:(NSString*)propertyName;
+ (NSDictionary*) rg_declarationForProperty:(NSString*)propertyName;
- (NSDictionary*) rg_declarationForProperty:(NSString*)propertyName;

@end