/* Copyright (c) 8/8/14, Ryan Dignard
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

#import "RDDAPIClient.h"
#import "RDDBartStation.h"

#define BART_API_BASE @"http://api.bart.gov/api"
#define BART_API_KEY @"MW9S-E7SL-26DU-VV8V"
#define API_KEY_PARAMETER @"key"
#define API_KEY_COMMAND @"cmd"
#define BART_API_VERSION @"2.0"
#define BART_API_VERSION_KEY @"apiVersion"

//Station Keys
#define ALL_STATIONS_COMMAND @"stns"

static inline NSMutableDictionary* basicsForCommand(NSString* command) {
    static dispatch_once_t onceToken;
    static NSDictionary* _sCredentials;
    dispatch_once(&onceToken, ^{
        _sCredentials = @{ API_KEY_PARAMETER : BART_API_KEY };
    });
    NSMutableDictionary* parameters = [_sCredentials mutableCopy];
    parameters[API_KEY_COMMAND] = command;
    return parameters;
}

@interface RDDAPIClient () <RGSerializationDelegate>

@end

@implementation RDDAPIClient

+ (instancetype) sharedManager {
    static dispatch_once_t onceToken;
    static id _sSharedManaged;
    dispatch_once(&onceToken, ^{
        _sSharedManaged = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"https://itunes.apple.com/"]];
    });
    return _sSharedManaged;
}

- (instancetype) initWithBaseURL:(NSURL *)baseURL sessionConfiguration:(id)session {
    self = [super initWithBaseURL:baseURL sessionConfiguration:session];
    self.serializationDelegate = self;
    return self;
}

- (void) getItunesArtist:(NSString*)artist {
    self.responseSerializer = [AFJSONResponseSerializer new];
    [self GET:@"/search"
   parameters:@{ @"term" : artist ?: @"" }
      keyPath:@"results"
        class:[RDDItunesEntry class]
   completion:^(RGResponseObject* response) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@(sel_getName(_cmd)) object:response.responseBody];
    }];
}

- (void) getStationsWithCompletion:(RGResponseBlock)completion {
    self.responseSerializer = [AFXMLParserResponseSerializer new];
    
    [self GET:@"http://api.bart.gov/api/stn.aspx"
   parameters:basicsForCommand(ALL_STATIONS_COMMAND)
      keyPath:@"root.stations.station"
        class:[RDDBartStation class]
   completion:^(RGResponseObject* response) {
       
        if (!response.error) {
            for (id obj in response.responseBody) {
                NSLog(@"%@", [(NSObject*)obj dictionaryRepresentation]);
            }
        }
        
        if (completion) completion(response);
    }];
}

- (BOOL) shouldSerializeXML {
    return YES;
}

@end
