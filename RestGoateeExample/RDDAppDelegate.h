//
//  RDDAppDelegate.h
//  RestGoateeExample
//
//  Created by Ryan Dignard on 8/8/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
