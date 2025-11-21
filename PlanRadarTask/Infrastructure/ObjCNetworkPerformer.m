//
//  ObjCNetworkPerformer.m
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//


#import "ObjCNetworkPerformer.h"

NS_ASSUME_NONNULL_BEGIN

static void ObjCLog(NSString *format, ...) {
#if DEBUG
    va_list args;
    va_start(args, format);
    NSString *formatted = [[NSString alloc] initWithFormat:format arguments:args];
    NSLog(@"%@", formatted);
    va_end(args);
#endif
}

static NSString *ObjCStringFromData(NSData * _Nullable data) {
    if (!data || data.length == 0) {
        return @"<empty>";
    }
    NSString *utf8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (utf8) {
        return utf8;
    }
    return @"<binary>";
}

@interface ObjCNetworkPerformer ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation ObjCNetworkPerformer

NSString * const ObjCNetworkErrorDomain = @"com.planradar.task.network";
NSString * const ObjCNetworkStatusCodeKey = @"ObjCNetworkStatusCodeKey";
NSString * const ObjCNetworkResponseDataKey = @"ObjCNetworkResponseDataKey";

- (instancetype)init {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    return [self initWithSession:session];
}

- (instancetype)initWithSession:(NSURLSession *)session {
    self = [super init];
    if (self) {
        _session = session;
    }
    return self;
}

- (void)performRequest:(NSURLRequest *)request completion:(ObjCNetworkCompletion)completion {
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData * _Nullable data,
                                                                     NSURLResponse * _Nullable response,
                                                                     NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            ObjCLog(@"Network error: %@", error);
            completion(nil, response, error);
            return;
        }

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode >= 400) {
                NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
                userInfo[ObjCNetworkStatusCodeKey] = @(httpResponse.statusCode);
                if (data) {
                    userInfo[ObjCNetworkResponseDataKey] = data;
                }
                NSError *statusError = [NSError errorWithDomain:ObjCNetworkErrorDomain
                                                           code:httpResponse.statusCode
                                                       userInfo:userInfo];
                ObjCLog(@"HTTP error %ld for URL %@", (long)httpResponse.statusCode, request.URL.absoluteString);
                [strongSelf logResponseData:data response:httpResponse];
                completion(nil, response, statusError);
                return;
            }
        }

        [strongSelf logResponseData:data response:response];
        completion(data, response, nil);
    }];

    [self logRequest:request];
    [task resume];
}

- (void)logRequest:(NSURLRequest *)request {
    ObjCLog(@"--------- ObjC Request ---------");
    ObjCLog(@"URL: %@", request.URL.absoluteString);
    ObjCLog(@"Method: %@", request.HTTPMethod ?: @"<unknown>");
    ObjCLog(@"Headers: %@", request.allHTTPHeaderFields ?: @{});
    if (request.HTTPBody) {
        ObjCLog(@"Body: %@", ObjCStringFromData(request.HTTPBody));
    }
}

- (void)logResponseData:(NSData * _Nullable)data response:(NSURLResponse * _Nullable)response {
    ObjCLog(@"--------- ObjC Response --------");
    if (response) {
        ObjCLog(@"Response class: %@", NSStringFromClass([response class]));
    }
    if (data) {
        ObjCLog(@"Payload: %@", ObjCStringFromData(data));
    }
}

@end

NS_ASSUME_NONNULL_END

