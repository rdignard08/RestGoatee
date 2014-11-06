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

/**
 Optionally use this function to provide your project's class prefix.
 
 XYZMyClass -> provide @"XYZ"
 */
void rg_setClassPrefix(const NSString* const prefix);

/**
 @abstract returns the currently set class prefix.  The default value is a string composed of the capitalized letters leading your application's appDelegate.  For example default when nothing is given takes `XYZApplicationDelegate` and returns @"XYZ".
 */
const NSString* const rg_classPrefix(void);

/**
 Optionally use this function to provide your server's type keyPath.
 
 @example
 
 Given a JSON body of:
 {
 "class" : "message"
 "message" : "hello!"
 }
 
 return literal `class` to indicate that the type of this object is found on the key "class" (in this case `message`).
 
 In conjuction with `rg_classPrefix(void)` this will construct the type to deserialize into as "XYZMessage" for this object.  If this type doesn't exist deserialization will look for its own indications, which if fail will return the original dictionary.
 */
void rg_setServerTypeKey(const NSString* const typeKey);

/**
 @abstract returns the currently set server type.  The default is `nil` if no value is set.
 */
const NSString* const rg_serverTypeKey(void);