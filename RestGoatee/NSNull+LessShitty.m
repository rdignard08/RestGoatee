/* Copyright (c) 7/7/14, Ryan Dignard
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
#import "NSNull+LessShitty.h"
#import <objc/runtime.h>

@implementation NSNull (Niller)

/**
 Garbage method to nil out a call (if requiring a value)
 */
- (id) __nil_objc_send {
    return nil;
}

- (void) forwardInvocation:(NSInvocation*)anInvocation {
    [anInvocation setSelector:@selector(__nil_objc_send)];
    [anInvocation invokeWithTarget:self];
}

/**
 We want to be able to handle any selector and return (nil if necessary) without throwing an exception.
 
 @discussion NSNull is horribly designed.  It should behave like an object version of nil, but instead it's just a retarded object that can't do anything other than indicate that it _should_ be nil, but some arbitrary limitation doesn't permit it.
 */
- (NSMethodSignature*) methodSignatureForSelector:(SEL)aSelector {
    NSUInteger numArgs = [[NSStringFromSelector(aSelector) componentsSeparatedByString:@":"] count] - 1;
    /* we assume that all arguments are objects (it really doesn't matter since we don't actually reference any arguments)
    * The type encoding is "@@:..." (... are {0,n] id), where "@" is the return type, id (some object-sized pointer)
    * "@" is the receiver (self), object type; ":" is the selector of the current method (_cmd);
    * and each "@" after corresponds to an object argument
    */
    static const NSString* const base = @"@@:";
    return [NSMethodSignature signatureWithObjCTypes:
            [[base stringByPaddingToLength:numArgs + base.length withString:@"@" startingAtIndex:0] UTF8String]];
}

@end
