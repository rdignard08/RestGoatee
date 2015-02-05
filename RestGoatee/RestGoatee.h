/* Copyright (c) 6/10/14, Ryan Dignard
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

extern const NSString* const kRGHTTPStatusCode; /* Key returned as part of HTTP related errors */

/**
 Optionally use this function to provide your project's class prefix.
 
 XYZMyClass -> provide @"XYZ"
 */
void rg_setClassPrefix(const NSString* const prefix);

/**
 @abstract returns the currently set class prefix.  The default value is a string composed of the capitalized letters leading your application's appDelegate.  For example default when nothing is given takes `XYZApplicationDelegate` and returns @"XYZ".
 */
const NSString* const rg_classPrefix(void);

/**
 Optionally use this function to provide your server's type keyPath.
 
 @example
 
 Given a JSON body of:
 {
 "class" : "message"
 "message" : "hello!"
 }
 
 return literal `class` to indicate that the type of this object is found on the key "class" (in this case `message`).
 
 In conjuction with `rg_classPrefix(void)` this will construct the type to deserialize into as "XYZMessage" for this object.  If this type doesn't exist deserialization will look for its own indications, which if fail will return the original dictionary.
 */
void rg_setServerTypeKey(const NSString* const typeKey);

/**
 @abstract returns the currently set server type.  The default is `nil` if no value is set.
 */
const NSString* const rg_serverTypeKey(void);

#ifdef DEBUG
    #define __SOURCE_FILE__ ({char* c = strrchr(__FILE__, '/'); c ? c + 1 : __FILE__;})
    #define RGLog(format, ...) _RGLog(format, __SOURCE_FILE__, (long)__LINE__, ##__VA_ARGS__)
    extern void _RGLog(NSString* format, ...);
#else
    /* we define out with `(void)0` generally this is `NULL` to allow constructs like `condition ?: RGLog(@"Blah")`. */
    #define RGLog(...) (void)0
#endif

#define DO_RISKY_BUSINESS \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-retain-cycles\"") \
_Pragma("clang diagnostic ignored \"-Wgnu\"") \
_Pragma("clang diagnostic ignored \"-Wunreachable-code\"") \
_Pragma("clang diagnostic ignored \"-Wundeclared-selector\"") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \

#define END_RISKY_BUSINESS \
_Pragma("clang diagnostic pop")

#define RISKY_BUSINESS(statement) \
DO_RISKY_BUSINESS \
statement \
END_RISKY_BUSINESS

#import "RGDataSourceProtocol.h"
#import "NSObject+RG_KeyedSubscripting.h"
#import "NSError+RG_HTTPStatusCode.h"
#import "RGResponseObject.h"


#import "NSObject+RG_Deserialization.h"
#import "NSObject+RG_Serialization.h"

#import "RGAPIClient.h"