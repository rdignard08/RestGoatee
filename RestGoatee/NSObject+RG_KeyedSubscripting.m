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

#import "RestGoatee.h"

@implementation NSObject (RG_KeyedSubscripting)

- (id) objectForKeyedSubscript:(id<NSCopying, NSObject>)key {
    @try {
        return [self valueForKey:[key description]];
    }
    @catch (NSException* e) {
        RGLog(@"Unknown property %@ on type %@: %@", [key description], [self class], e);
        return nil;
    }
}

- (void) setObject:(id)obj forKeyedSubscript:(id<NSCopying, NSObject>)key {
    @try {
        [self setValue:obj forKey:[key description]]; /* This is _intentionally_ not -setObject, -setValue is smarter; see the docs */
    }
    @catch (NSException* e) {
        RGLog(@"Unknown property %@ on type %@: %@", [key description], [self class], e);
    }
}

@end

@implementation NSMutableDictionary (RG_KeyedSubscripting)

/* fuck you apple */
- (void) setObject:(id)obj forKeyedSubscript:(id<NSCopying,NSObject>)key {
    if (obj) {
        [self setObject:obj forKey:key];
    } else {
        [self removeObjectForKey:key];
    }
}

@end