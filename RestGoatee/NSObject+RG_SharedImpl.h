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

/**
 forward declaration from <objc/runtime.h>
 */
struct objc_property;

/**
 forward declaration from <objc/runtime.h>
 */
struct objc_ivar;

/* Some notes on property attributes, declaration modifiers '
    assign is exactly the same unsafe_unretained 
    retain is exactly the same as strong
    __block implies strong
    backing ivars are usually `_<propertyName>` however older compilers sometimes named them the same
 */

/* Property Description Keys */

/**
 The key associated with the name of one of the class's properties.
 */
extern NSString* const kRGPropertyName;

/**
 The key associated with the canonical name of one of the class's properties.
 
 canonical names are used to match disparate keys to the same meta key. This is to say that the keys "fooBar" and "foo_bar" share the same meta/canonical key and will be resolved to the same entry.
 */
extern NSString* const kRGPropertyCanonicalName;

/**
 The key associated with a property's storage qualifier (i.e. `assign`, `weak`, `strong`, `copy`, `unsafe_unretained`).
 */
extern NSString* const kRGPropertyStorage;

/**
 The key associated with a property's atomic nature (i.e. `atomic`, `nonatomic`).
 */
extern NSString* const kRGPropertyAtomicType;

/**
 The key associated with a property's public declaration (i.e. `readonly`, `readwrite`).
 */
extern NSString* const kRGPropertyAccess;

/**
 The key associated with a property's backing instance variable (if any).  Pass through properties will appear to have no backing state for example.
 */
extern NSString* const kRGPropertyBacking;

/**
 The key associated with a property's getter method (if non-standard; for example on `fooBar`: `isFooBar`).
 */
extern NSString* const kRGPropertyGetter;

/**
 The key associated with a property's setter method (if non-standard; for example on `fooBar`: `setIsFooBar`).
 */
extern NSString* const kRGPropertySetter;

/**
 This value on the key `kRGPropertyAccess` indicates the property is `readwrite`.
 */
extern NSString* const kRGPropertyReadwrite;

/**
 This value on the key `kRGPropertyAccess` indicates the property is `readonly`.
 */
extern NSString* const kRGPropertyReadonly;

/**
 This value on the key `kRGPropertyStorage` indicates the property is `assign`.
 */
extern NSString* const kRGPropertyAssign;

/**
 This value on the key `kRGPropertyStorage` indicates the property is `strong`.
 */
extern NSString* const kRGPropertyStrong;

/**
 This value on the key `kRGPropertyStorage` indicates the property is `copy`.
 */
extern NSString* const kRGPropertyCopy;

/**
 This value on the key `kRGPropertyStorage` indicates the property is `weak`.
 */
extern NSString* const kRGPropertyWeak;

/**
 The key associated with the class type of this property.
 */
extern NSString* const kRGPropertyClass;

/**
 The key associated with the general type of this property.  Represents structs, pointers, primitives, etc.
 */
extern NSString* const kRGPropertyRawType;

/**
 This value on the key `kRGPropertyBacking` indicates the property was declared `@dynamic`.  Mutually exclusive with the presence of a backing instance variable.
 */
extern NSString* const kRGPropertyDynamic;

/**
 This value on the key `kRGPropertyAtomicType` indicates the property is `atomic`.
 */
extern NSString* const kRGPropertyAtomic;

/**
 This value on the key `kRGPropertyAtomicType` indicates the property is `nonatomic`.
 */
extern NSString* const kRGPropertyNonatomic;

/**
 This key is inserted into `NSDictionary*` instances which are serialized by this library.  It facilitates easier reconversion back to the original type.  Usage:
 ```
 FooBar* fooBar = ...;
 ...
 NSDictionary* serialized = [fooBar dictionaryRepresentation];
 ...
 id originalObject = [NSClassFromString(serialized[kRGSerializationKey]) objectFromDataSource:serialized];
 ```
 */
extern NSString* const kRGSerializationKey;

/**
 This key indicates the class meta data that the library uses for all other operations.
 */
extern NSString* const kRGPropertyListProperty;

/* Ivar Description Keys */

/**
 This key indicates the byte offset of the given instance variable into an instance of the class.
 
 Raw access can be accomplished with:
 `void* address = (unsigned char*)obj + [meta[kRGIvarOffset] unsignedLongLongValue];`
 Then use the value available on `kRGIvarSize` to deference and get the raw value.
 
 Granted you shouldn't do this. The run-time supports it, so it's not my place to artificially limit.
 */
extern NSString* const kRGIvarOffset;

/**
 This key indicates the byte size of the given instance variable.
 */
extern NSString* const kRGIvarSize;

/**
 This instance variable was marked `@private`.
 */
extern NSString* const kRGIvarPrivate;

/**
 This instance variable was marked `@protected`.
 */
extern NSString* const kRGIvarProtected;

/**
 This instance variable was marked `@public`.
 */
extern NSString* const kRGIvarPublic;

/* These classes are used to dynamically link into coredata if present. */

/**
 Will be `[NSManagedObjectContext class]` or `nil` (if not linked/available).
 */
Class rg_sNSManagedObjectContext;

/**
 Will be `[NSManagedObject class]` or `nil` (if not linked/available).
 */
Class rg_sNSManagedObject;

/**
 Will be `[NSManagedObjectModel class]` or `nil` (if not linked/available).
 */
Class rg_sNSManagedObjectModel;

/**
 Will be `[NSPersistentStoreCoordinator class]` or `nil` (if not linked/available).
 */
Class rg_sNSPersistentStoreCoordinator;

/**
 Will be `[NSEntityDescription class]` or `nil` (if not linked/available).
 */
Class rg_sNSEntityDescription;

/**
 Will be `[NSFetchRequest class]` or `nil` (if not linked/available).
 */
Class rg_sNSFetchRequest;

/**
 Returns the built-in date formats the library supports. Contains: ISO, `-[NSDate description]`.
 */
NSArray* const rg_dateFormats(void);

/**
 Taking in an array, will attempt to construct non dictionary / xml node objects.
 */
NSArray* rg_unpackArray(NSArray* json, id context);

/**
 modify the `__property_list__` declarations to include information from the backing instance variable.
 */
void rg_parseIvarStructOntoPropertyDeclaration(struct objc_ivar* ivar, NSMutableDictionary* propertyData);

/**
 modifies the `properties` param to have the ivar size available.
 */
void rg_calculateIvarSize(Class object, NSMutableArray/*NSMutableDictionary*/* properties);

/**
 return the details about the backing ivar as an object.
 */
NSMutableDictionary* rg_parseIvarStruct(struct objc_ivar* ivar);
/**
 Returns the property name in as its canonical key.
 */
NSString* const rg_canonicalForm(NSString* const input);

/**
 Returns true if `Class cls = object;` is not a pointer type conversion.
 */
BOOL rg_isClassObject(id object);

/**
 Returns true if object has the same type as `NSObject`'s meta class.
 */
BOOL rg_isMetaClassObject(id object);

/**
 Returns true if the given type can be adequately represented by an `NSString`.
 */
BOOL rg_isInlineObject(Class cls);

/**
 Returns true if the given type can be adequately represented by an `NSArray`.
 */
BOOL rg_isCollectionObject(Class cls);

/**
 Returns true if the given type is a "key => value" type.  Thus it can be represented by an `NSDictionary`.
 */
BOOL rg_isKeyedCollectionObject(Class cls);

/**
 Returns true if the given class conforms to `RGDataSourceProtocol`.  Necessary due to some bug.
 */
BOOL rg_isDataSourceClass(Class cls);

/**
 Returns a `Class` object (i.e. an Objective-C object type), from the given type string.
 */
Class rg_classForTypeString(NSString* str);

/**
 converts the raw property struct from the run-time system into an `NSDictionary`.
 */
NSDictionary* rg_parsePropertyStruct(struct objc_property* property);

/**
 If the value of `str` has 2 '"' this function returns the contents between each '"'.
 */
NSString* rg_trimLeadingAndTrailingQuotes(NSString* str);

/**
 Return the class object which is responsible for providing the implementation of a given `self.propertyName` invocation.
 
 multiple classes may implement the same property, in this instance, only the top (i.e. the most subclass Class object) is returned.
 
 @param currentClass is the object to test
 @param propertyName is the name of the property
 */
Class topClassDeclaringPropertyNamed(Class currentClass, NSString* propertyName);

/**
 This is a private category which contains all the of the methods used jointly by the categories `RG_Deserialization` and `RG_Serialization`.
 */
@interface NSObject (RG_SharedImpl)

/**
 This is a readonly property that describes the meta data of the given receiver's class.  It declares properties and instance variables in an object accessible manner.
 */
@property (nonatomic, strong, readonly) NSArray* __property_list__;

/**
 This function returns the output keys of the receiver for use when determining what state information is present in the instance.
 */
@property (nonatomic, strong, readonly) NSArray* rg_keys;

/**
 Returns a `Class` object which is the type of the property specified by `propertyName`; defaults to `NSNumber` if unknown.
 */
- (Class) rg_classForProperty:(NSString*)propertyName;

/**
 Returns `YES` if the type of the property is an object type (as known by `NSClassFromString()`).
 */
- (BOOL) rg_isPrimitive:(NSString*)propertyName;

/**
 Returns the metadata for the property specified by `propertyName`.
 */
+ (NSDictionary*) rg_declarationForProperty:(NSString*)propertyName;

/**
 The instance equivalent of `+[NSObject rg_declarationForProperty:]`.  No behavioral differences.
 */
- (NSDictionary*) rg_declarationForProperty:(NSString*)propertyName;

@end
