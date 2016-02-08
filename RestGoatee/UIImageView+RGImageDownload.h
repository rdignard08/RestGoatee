/* Copyright (c) 09/07/2015, Ryan Dignard
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

#import "RestGoatee-Core.h"
#import <UIKit/UIKit.h>

@class AFHTTPRequestOperation;

void rg_setImageWithURL(UIImageView* RG_SUFFIX_NULLABLE self,
                     NSURLRequest* RG_SUFFIX_NONNULL urlRequest,
                     UIImage* RG_SUFFIX_NULLABLE placeholderImage,
                     void(^RG_SUFFIX_NULLABLE success)(NSHTTPURLResponse* RG_SUFFIX_NULLABLE, UIImage* RG_SUFFIX_NULLABLE),
                     void(^RG_SUFFIX_NULLABLE failure)(NSHTTPURLResponse* RG_SUFFIX_NULLABLE, NSError* RG_SUFFIX_NONNULL));

id RG_SUFFIX_NULLABLE rg_resourceForURL(UIImageView* RG_SUFFIX_NULLABLE self, NSURLRequest* RG_SUFFIX_NONNULL url, void(^ RG_SUFFIX_NULLABLE handler)(AFHTTPRequestOperation* RG_SUFFIX_NULLABLE, id RG_SUFFIX_NULLABLE));

@interface UIImageView (RGImageDownload)

@property RG_NULLABLE_PROPERTY(nonatomic, strong) AFHTTPRequestOperation* rg_pendingOperation;

- (void) rg_setImageWithURL:(RG_PREFIX_NONNULL NSURL*)url;

- (void) rg_setImageWithURL:(RG_PREFIX_NONNULL NSURL*)url placeholder:(RG_PREFIX_NULLABLE UIImage*)placeholder;

- (void) rg_setImageWithURL:(RG_PREFIX_NONNULL NSURL*)url placeholder:(RG_PREFIX_NULLABLE UIImage*)placeholder success:(void(^ RG_SUFFIX_NULLABLE)(NSHTTPURLResponse* RG_SUFFIX_NULLABLE, UIImage* RG_SUFFIX_NULLABLE))success failure:(void(^ RG_SUFFIX_NULLABLE)(NSHTTPURLResponse* RG_SUFFIX_NULLABLE, NSError* RG_SUFFIX_NONNULL))failure;

@end

/**
 STCacheBlock is a block type which will be retained forever and invoked periodically to determine space available for files.
 */
typedef uint64_t (^STCacheBlock)(void);

/**
 provide a `STCacheBlock` to be called on file system changes.  Return the maximum number of bytes allowed.
 */
void setFileCacheLimit(STCacheBlock RG_SUFFIX_NONNULL handler);

@interface NSFileManager (Startup)

/**
 A wrapped `uint64_t` representing the total file content size stored within a directory.
 */
- (RG_PREFIX_NONNULL NSNumber*) sizeForFolderAtPath:(RG_PREFIX_NONNULL NSURL*)source error:(NSError* RG_SUFFIX_NULLABLE * RG_SUFFIX_NULLABLE)error;

@end
