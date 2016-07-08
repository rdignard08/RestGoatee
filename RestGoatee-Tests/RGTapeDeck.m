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

#import "RGTapeDeck.h"
#import "RestGoatee.h"
#import <objc/runtime.h>

@interface RGTapeDeck ()

@property (nonatomic, strong) NSLock* sharedLock;
@property (nonatomic, strong) NSMutableDictionary* tapeDeck;
@property (nonatomic, strong) NSMutableDictionary* statusCodes;

@end

@implementation NSURLSessionTask (RGTestOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (void) override_resume {
    NSURLSession* session = [self performSelector:@selector(session)];
    NSDictionary* delegates = [session.delegate performSelector:@selector(mutableTaskDelegatesKeyedByTaskIdentifier)];
    id<NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate> taskDelegate = delegates[@(self.taskIdentifier)];
    NSURLComponents* components = [NSURLComponents componentsWithURL:self.currentRequest.URL resolvingAgainstBaseURL:NO];
    components.query = nil;
    [[RGTapeDeck sharedTapeDeck].sharedLock lock];
    NSData* data = [RGTapeDeck sharedTapeDeck].tapeDeck[components.URL.absoluteString];
    [[RGTapeDeck sharedTapeDeck].sharedLock unlock];
    [taskDelegate URLSession:session dataTask:(id)self didReceiveData:data];
    NSUInteger statusCode = [[RGTapeDeck sharedTapeDeck].statusCodes[components.URL.absoluteString] unsignedIntegerValue];
    if (statusCode >= 200 && statusCode < 300) {
        [taskDelegate URLSession:session task:self didCompleteWithError:nil];
    } else {
        NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1011 userInfo:@{ NSLocalizedDescriptionKey : @"The operation couldn't be completed(-1011)." }];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:components.URL statusCode:statusCode HTTPVersion:nil headerFields:nil];
        [self setValue:response forKey:@"response"];
        [taskDelegate URLSession:session task:self didCompleteWithError:error];
    }
}
#pragma clang diagnostic pop

@end

@implementation RGTapeDeck

+ (void) initialize {
    Class cls = NSClassFromString(@"__NSCFLocalDataTask");
    method_exchangeImplementations(class_getInstanceMethod(cls, @selector(resume)),
                                   class_getInstanceMethod(cls, @selector(override_resume)));
}

+ (RGTapeDeck*) sharedTapeDeck {
    static dispatch_once_t onceToken;
    static RGTapeDeck* deck;
    dispatch_once(&onceToken, ^{
        deck = [RGTapeDeck new];
        deck.sharedLock = [NSLock new];
        deck.tapeDeck = [NSMutableDictionary new];
        deck.statusCodes = [NSMutableDictionary new];
    });
    return deck;
}

- (void) playTape:(NSString*)tapeName forURL:(NSString*)url withCode:(NSUInteger)statusCode {
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:tapeName ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    [self.sharedLock lock];
    self.tapeDeck[url] = data ?: [NSData new];
    self.statusCodes[url] = @(statusCode);
    [self.sharedLock unlock];
}

- (void) removeTapeForURL:(NSString*)url {
    [self.sharedLock lock];
    [self.tapeDeck removeObjectForKey:url];
    [self.statusCodes removeObjectForKey:url];
    [self.sharedLock unlock];
}

- (void) removeAllTapes {
    [self.sharedLock lock];
    [self.tapeDeck removeAllObjects];
    [self.statusCodes removeAllObjects];
    [self.sharedLock unlock];
}

@end
