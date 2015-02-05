//
//  RDDAppDelegate.m
//  RestGoateeExample
//
//  Created by Ryan Dignard on 8/8/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

#import "RDDAppDelegate.h"
#import "RDDViewController.h"

@interface RDDAppDelegate ()
@property (readwrite, strong, nonatomic) NSManagedObjectContext* managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@end

static NSString* const applicationName = @"RestGoateeExample";

@implementation RDDAppDelegate
@synthesize window = _window; //thanks apple.

#pragma mark - UIApplicationDelegate
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    RDDViewController* rootViewController = [[RDDViewController alloc] initWithNibName:NSStringFromClass([RDDViewController class]) bundle:nil];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) applicationWillTerminate:(UIApplication*)application {
    [self saveContext]; // Saves changes in the application's managed object context before the application terminates.
}

#pragma mark -
- (void) saveContext {
    NSError* error;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

- (NSURL*) applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Properties
- (UIWindow*) window {
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _window;
}

- (NSManagedObjectContext*) managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = [NSManagedObjectContext new];
        _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel*) managedObjectModel {
    if (!_managedObjectModel) {
        NSURL* modelURL = [[NSBundle mainBundle] URLForResource:applicationName withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        NSURL* datafileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@.sqlite", applicationName] relativeToURL:[self applicationDocumentsDirectory]];
        NSError* error;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil URL:datafileURL
                                                             options:@{
                                                                       NSMigratePersistentStoresAutomaticallyOption : @YES,
                                                                       NSInferMappingModelAutomaticallyOption : @YES
                                                                       }
                                                               error:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

@end
