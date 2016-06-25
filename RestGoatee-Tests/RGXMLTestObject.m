/* Copyright (c) 05/29/2016, Ryan Dignard
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

#import "RGXMLTestObject.h"
#import "RGTestManagedObject.h"

@implementation RGXMLTestObject

- (void) setValue:(NSString*)value {
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _value = value;
}

- (NSManagedObjectContext*) contextForManagedObjectType:(NSString *)type {
    static dispatch_once_t onceToken;
    static NSManagedObjectContext* context;
    dispatch_once(&onceToken, ^{
        NSEntityDescription* entity = [NSEntityDescription new];
        NSAttributeDescription* idAttribute = [NSAttributeDescription new];
        idAttribute.attributeType = NSStringAttributeType;
        idAttribute.name = RG_STRING_SEL(trackId);
        entity.properties = @[ idAttribute ];
        entity.name = NSStringFromClass([RGTestManagedObject self]);
        entity.managedObjectClassName = entity.name;
        NSManagedObjectModel* model = [NSManagedObjectModel new];
        model.entities = @[ entity ];
        NSPersistentStoreCoordinator* store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        [store addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.persistentStoreCoordinator = store;
    });
    return context;
}

- (RG_PREFIX_NULLABLE NSString*) keyForReconciliationOfType:(RG_PREFIX_NONNULL Class)cls {
    return self.primaryKey;
}

- (BOOL) shouldRetryRequest:(RG_PREFIX_NULLABLE NSURLRequest*)request
                   response:(RG_PREFIX_NULLABLE NSURLResponse*)response
                      error:(RG_PREFIX_NONNULL NSError*)error
                 retryCount:(NSUInteger)count {
    return count <= 2;
}

- (BOOL) shouldSerializeXML {
    return YES;
}

@end
