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

static const NSString* _sClassPrefix;
const NSString* const rg_classPrefix() {
    @synchronized ([NSObject class]) {
        if (!_sClassPrefix) {
            NSString* appDelegateName = [[[UIApplication sharedApplication].delegate class] description];
            for (NSUInteger i = 0; i < appDelegateName.length; i++) {
                unichar c = [appDelegateName characterAtIndex:i];
                if (c < 'A' || c > 'Z') { /* if it's not a capital letter, we've found the end of the prefix */
                    _sClassPrefix = [appDelegateName stringByReplacingCharactersInRange:NSMakeRange(i == 0 ?: i - 1, i == 0 ? appDelegateName.length : appDelegateName.length - i + 1) withString:@""]; /* the last capital character is not part of the prefix since it's the class name */
                    break;
                }
            }
            if (!_sClassPrefix) {
                _sClassPrefix = @""; /* In case nothing is found, we still want to return some string */
            }
        }
    }
    return _sClassPrefix;
}

void rg_setClassPrefix(const NSString* const prefix) {
    @synchronized ([NSObject class]) {
        _sClassPrefix = prefix;
    }
}

static const NSString* _sServerTypeKey;
void rg_setServerTypeKey(const NSString* const typeKey) {
    @synchronized ([NSObject class]) {
        _sServerTypeKey = typeKey;
    }
}

const NSString* const rg_serverTypeKey() {
    @synchronized ([NSObject class]) {
        return _sServerTypeKey;
    }
}

extern void _RGLog(NSString* format, ...) {
    va_list vl;
    va_start(vl, format);
    char* fileName = va_arg(vl, char*);
    long lineNumber = va_arg(vl, long);
    NSString* line = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"[%@:%@] %@", @(fileName), @(lineNumber), format] arguments:vl];
    fprintf(stderr, "%s\n", [line UTF8String]);
    va_end(vl);
}
