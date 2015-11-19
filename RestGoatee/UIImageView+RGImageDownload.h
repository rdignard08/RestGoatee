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

#import <AFNetworking/AFNetworking.h>
#import <RestGoatee-Core.h>

NS_ASSUME_NONNULL_BEGIN

void rg_setImageWithURL(UIImageView* __nullable self,
                     NSURLRequest* __nonnull urlRequest,
                     UIImage* __nullable placeholderImage,
                     void(^__nullable success)(NSHTTPURLResponse* __nullable, UIImage* __nullable),
                     void(^__nullable failure)(NSHTTPURLResponse* __nullable, NSError* __nonnull));

id RG_SUFFIX_NULLABLE rg_resourceForURL(UIImageView* __nullable self, NSURLRequest* __nonnull url, void(^ RG_SUFFIX_NULLABLE handler)(AFHTTPRequestOperation* __nullable, id __nullable));

@interface UIImageView (RGImageDownload)

@property (nonatomic, strong, nullable) AFHTTPRequestOperation* rg_pendingOperation;

- (void) rg_setImageWithURL:(nonnull NSURL*)url;

- (void) rg_setImageWithURL:(nonnull NSURL*)url placeholder:(nullable UIImage*)placeholder;

- (void) rg_setImageWithURL:(nonnull NSURL*)url placeholder:(nullable UIImage*)placeholder success:(void(^ __nullable)(NSHTTPURLResponse* __nullable, UIImage* __nullable))success failure:(void(^ __nullable)(NSHTTPURLResponse* __nullable, NSError* __nonnull))failure;

@end

/**
 STCacheBlock is a block type which will be retained forever and invoked periodically to determine space available for files.
 */
typedef uint64_t (^STCacheBlock)(void);

/**
 provide a `STCacheBlock` to be called on file system changes.  Return the maximum number of bytes allowed.
 */
void setFileCacheLimit(STCacheBlock __nonnull handler);

@interface NSFileManager (Startup)

/**
 A wrapped `uint64_t` representing the total file content size stored within a directory.
 */
- (nonnull NSNumber*) sizeForFolderAtPath:(nonnull NSURL*)source error:(NSError* __nullable * __nullable)error;

@end

NS_ASSUME_NONNULL_END
