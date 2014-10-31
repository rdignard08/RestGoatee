//  RGAPIClient+RG_ForwardDeclarationForObjectProxy.h
//
//  Created by Ryan Dignard on 10/31/14.

#import "RGAPIClient.h"

@class NSURLSessionDataTask, NSURLSessionConfiguration, NSProgress, AFHTTPRequestSerializer, AFSecurityPolicy, AFNetworkReachabilityManager;
@protocol AFURLRequestSerialization, AFURLResponseSerialization;

@interface RGAPIClient (RG_ForwardDeclarationForObjectProxy) <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSSecureCoding, NSCopying>

#pragma mark - AFHTTPRequestOperationManager
@property (readonly, nonatomic, strong) NSURL *baseURL;

@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;

//@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;

+ (instancetype) manager;

- (instancetype) initWithBaseURL:(NSURL*)url;

- (instancetype) initWithBaseURL:(NSURL*)url sessionConfiguration:(NSURLSessionConfiguration*)configuration;

- (NSURLSessionDataTask*) GET:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) HEAD:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) POST:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) POST:(NSString*)URLString parameters:(id)parameters constructingBodyWithBlock:(void(^)(id<AFMultipartFormData> formData))block success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) PUT:(NSString*)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) PATCH:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) DELETE:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

#pragma mark - AFHTTPSessionManager
//@property (readonly, nonatomic, strong) NSURL *baseURL;

//@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;

//@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;

+ (instancetype) manager;

- (instancetype) initWithBaseURL:(NSURL*)url;

- (instancetype)initWithBaseURL:(NSURL*)url sessionConfiguration:(NSURLSessionConfiguration*)configuration;

- (NSURLSessionDataTask*) GET:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) HEAD:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) POST:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError*error))failure;

- (NSURLSessionDataTask*) POST:(NSString*)URLString parameters:(id)parameters constructingBodyWithBlock:(void(^)(id<AFMultipartFormData> formData))block success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) PUT:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) PATCH:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

- (NSURLSessionDataTask*) DELETE:(NSString*)URLString parameters:(id)parameters success:(void(^)(NSURLSessionDataTask* task, id responseObject))success failure:(void(^)(NSURLSessionDataTask* task, NSError* error))failure;

#pragma mark - AFURLSessionManager
@property (readonly, nonatomic, strong) NSURLSession *session;

@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) id <AFURLResponseSerialization> responseSerializer;

@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

@property (readwrite, nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;

@property (readonly, nonatomic, strong) NSArray *tasks;

@property (readonly, nonatomic, strong) NSArray *dataTasks;

@property (readonly, nonatomic, strong) NSArray *uploadTasks;

@property (readonly, nonatomic, strong) NSArray *downloadTasks;

@property (nonatomic, strong) dispatch_queue_t completionQueue;

@property (nonatomic, strong) dispatch_group_t completionGroup;

@property (nonatomic, assign) BOOL attemptsToRecreateUploadTasksForBackgroundSessions;

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(NSProgress * __autoreleasing *)progress
                                        completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(NSProgress * __autoreleasing *)progress
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(NSProgress * __autoreleasing *)progress
                                             destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

- (NSProgress *)uploadProgressForTask:(NSURLSessionUploadTask *)uploadTask;

- (NSProgress *)downloadProgressForTask:(NSURLSessionDownloadTask *)downloadTask;

- (void)setSessionDidBecomeInvalidBlock:(void (^)(NSURLSession *session, NSError *error))block;

- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

- (void)setTaskNeedNewBodyStreamBlock:(NSInputStream * (^)(NSURLSession *session, NSURLSessionTask *task))block;

- (void)setTaskWillPerformHTTPRedirectionBlock:(NSURLRequest * (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block;

- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

- (void)setTaskDidSendBodyDataBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block;

- (void)setTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))block;

- (void)setDataTaskDidReceiveResponseBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block;

- (void)setDataTaskDidBecomeDownloadTaskBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask))block;

- (void)setDataTaskDidReceiveDataBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block;

- (void)setDataTaskWillCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse))block;

- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block;

- (void)setDownloadTaskDidFinishDownloadingBlock:(NSURL * (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location))block;

- (void)setDownloadTaskDidWriteDataBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))block;

- (void)setDownloadTaskDidResumeBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes))block;

#pragma mark - AFHTTPClient
//@property (readonly, nonatomic, strong) NSURL *baseURL;

@property (nonatomic, assign) NSStringEncoding stringEncoding;

//@property (nonatomic, assign) AFHTTPClientParameterEncoding parameterEncoding;

//@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

#ifdef _SYSTEMCONFIGURATION_H
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;
#endif

@property (nonatomic, assign) BOOL allowsInvalidSSLCertificate;

+ (instancetype)clientWithBaseURL:(NSURL *)url;

- (id)initWithBaseURL:(NSURL *)url;

#ifdef _SYSTEMCONFIGURATION_H
- (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block;
#endif

- (BOOL)registerHTTPOperationClass:(Class)operationClass;

- (void)unregisterHTTPOperationClass:(Class)operationClass;

- (NSString *)defaultValueForHeader:(NSString *)header;

- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value;

- (void)setAuthorizationHeaderWithUsername:(NSString *)username
                                  password:(NSString *)password;

- (void)setAuthorizationHeaderWithToken:(NSString *)token;

- (void)clearAuthorizationHeader;

- (void)setDefaultCredential:(NSURLCredential *)credential;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation;

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path;

- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)urlRequests
                                          progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                        completionBlock:(void (^)(NSArray *operations))completionBlock;

- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock;

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end