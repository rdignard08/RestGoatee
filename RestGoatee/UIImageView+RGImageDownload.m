/* Copyright (c) 9/7/15, Ryan Dignard
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

#import "UIImageView+RGImageDownload.h"
#import <objc/runtime.h>

@interface NSOperation (RGCompletionBlocks)

@property (nonatomic, strong, readonly) NSMutableArray* completionBlocks;

@end

@implementation NSOperation (RGCompletionBlocks)

- (NSMutableArray*)completionBlocks {
    id ret = objc_getAssociatedObject(self, @selector(completionBlocks));
    if (!ret) {
        ret = [NSMutableArray new];
        objc_setAssociatedObject(self, @selector(completionBlocks), ret, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ret;
}

@end

@implementation UIImageView (RGImageDownload)

+ (void)load {
    [self rg_imageCache];
    [self rg_imageCacheLock];
    [self rg_imageCacheFileManager];
    [self rg_cacheOperationQueue];
}

+ (NSLock*)rg_imageCacheLock {
    static dispatch_once_t onceToken;
    static NSLock* _sImageCachedLock;
    dispatch_once(&onceToken, ^{
        _sImageCachedLock = [NSLock new];
    });
    return _sImageCachedLock;
}

+ (NSCache*)rg_imageCache {
    static dispatch_once_t onceToken;
    static NSCache* _sImageCache;
    dispatch_once(&onceToken, ^{
        _sImageCache = [NSCache new];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[UIImageView rg_cacheOperationQueue] usingBlock:^(__unused id notification) {
            [_sImageCache removeAllObjects];
        }];
    });
    return _sImageCache;
}

+ (NSFileManager*)rg_imageCacheFileManager {
    static dispatch_once_t onceToken;
    static NSFileManager* _sFileManager;
    dispatch_once(&onceToken, ^{
        _sFileManager = [NSFileManager new];
    });
    return _sFileManager;
}

+ (NSOperationQueue*)rg_cacheOperationQueue {
    static dispatch_once_t onceToken;
    static NSOperationQueue* _sCachedOperationQueue;
    dispatch_once(&onceToken, ^{
        _sCachedOperationQueue = [NSOperationQueue new];
    });
    return _sCachedOperationQueue;
}

- (AFHTTPRequestOperation*)rg_pendingOperation {
    return objc_getAssociatedObject(self, @selector(rg_pendingOperation));
}

- (void)setRg_pendingOperation:(AFHTTPRequestOperation*)rg_pendingOperation {
    objc_setAssociatedObject(self, @selector(rg_pendingOperation), rg_pendingOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) rg_setImageWithURL:(NSURL*)url {
    [self rg_setImageWithURL:url placeholder:nil success:nil failure:nil];
}

- (void) rg_setImageWithURL:(NSURL*)url placeholder:(UIImage*)placeholder {
    [self rg_setImageWithURL:url placeholder:placeholder success:nil failure:nil];
}

- (void) rg_setImageWithURL:(NSURL*)url placeholder:(UIImage*)placeholder success:(void(^)(NSHTTPURLResponse*, UIImage*))success failure:(void(^)(NSHTTPURLResponse*, NSError*))failure {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"image/*" forHTTPHeaderField:@"Accept"];
    rg_setImageWithURL(self, request, placeholder, success, failure);
}

@end

void(^saveImageBlock)(UIImage*, NSString*) = ^(UIImage* image, NSString* path) {
    // TODO: save image to disk
};

/**
 This method is thread safe.
 
 Return values:
 AFHTTPRequestOperation = I've started downloading this resource (now or previously).
 NSNull = I've tried downloading it before and it failed on our end (4xx response).
 UIImage = I've downloaded this image successful. Will check memory and disk.
 */
id rg_resourceForURL(UIImageView* self, NSURLRequest* url, void(^handler)(AFHTTPRequestOperation*, id)) {
    static void(^standardCompletionBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation* op, id response) {
        [[UIImageView rg_imageCacheLock] lock];
        if ([response isKindOfClass:[UIImage class]]) {
            [[UIImageView rg_imageCache] setObject:response forKey:op.response.URL.path];
            [[UIImageView rg_cacheOperationQueue] addOperationWithBlock:^{
                saveImageBlock(response, op.response.URL.path);
            }];
        } else if (op.response.statusCode >= 400 && op.response.statusCode < 500) {
            NSLog(@"Bad image request %@", op.response.URL);
            [[UIImageView rg_imageCache] setObject:[NSNull null] forKey:op.response.URL.path];
        }
        for (void(^completionBlock)(AFHTTPRequestOperation*, id) in op.completionBlocks) {
            completionBlock(op, response);
        }
        [op.completionBlocks removeAllObjects];
        [[UIImageView rg_imageCacheLock] unlock];
    };
    
    [[UIImageView rg_imageCacheLock] lock];
    
    id resource = [[UIImageView rg_imageCache] objectForKey:url.URL.path];
    
    if (!resource) {
        // TODO: check disk for image
    }
    
    if (!resource) { // make a new request
        resource = [[AFHTTPRequestOperation alloc] initWithRequest:url];
        [(AFHTTPRequestOperation*)resource setResponseSerializer:[AFImageResponseSerializer new]];
        [resource setCompletionBlockWithSuccess:standardCompletionBlock failure:standardCompletionBlock];
        [[[UIImageView class] rg_cacheOperationQueue] addOperation:resource];
        self.rg_pendingOperation.queuePriority = NSOperationQueuePriorityNormal;
        self.rg_pendingOperation = resource;
        [[UIImageView rg_imageCache] setObject:resource forKey:url.URL.path];
    }
    
    if ([resource isKindOfClass:[AFHTTPRequestOperation class]]) {
        self.rg_pendingOperation.queuePriority = self ? NSOperationQueuePriorityHigh : NSOperationQueuePriorityNormal;
        [[(AFHTTPRequestOperation*)resource completionBlocks] addObject:handler];
    }
    
    [[UIImageView rg_imageCacheLock] unlock];
    
    return resource;
}

void rg_setImageWithURL(UIImageView* self,
                        NSURLRequest* urlRequest,
                        UIImage* placeholderImage,
                        void(^success)(NSHTTPURLResponse*, UIImage*),
                        void(^failure)(NSHTTPURLResponse*, NSError*)) {
                            
    __weak typeof(self) weakSelf = self;
    id resource = rg_resourceForURL(self, urlRequest, ^(AFHTTPRequestOperation* op, id response) {
        __strong typeof(self) strongSelf = weakSelf;
        if (op == strongSelf.rg_pendingOperation || !strongSelf) { /* if the view dealloc'd we will still call to the blocks */
            strongSelf.rg_pendingOperation = nil;
            dispatch_async(dispatch_get_main_queue(), ^{ /* request was performed on a background thread */
                __strong typeof(self) strongSelf = weakSelf;
                if ([response isKindOfClass:[UIImage class]] && success) { /* success block will do something... */
                    success(op.response, response);
                } else if ([response isKindOfClass:[UIImage class]]) { /* no success block, assign it ourselves */
                    strongSelf.image = response;
                } else if (failure) { /* not an image, something went wrong! */
                    failure(op.response, response);
                }
            });
        }
    });
    
    if ([resource isKindOfClass:[NSNull class]]) { /* failed request */
        if (success) {
            success(nil, nil);
        } else {
            self.image = nil;
        }
    } else if ([resource isKindOfClass:[UIImage class]]) { /* successful previous request */
        if (success) {
            success(nil, resource);
        } else {
            self.image = resource;
        }
    } else { /* there's an on going request */
        if (placeholderImage) {
            self.image = placeholderImage;
        }
    }
}
