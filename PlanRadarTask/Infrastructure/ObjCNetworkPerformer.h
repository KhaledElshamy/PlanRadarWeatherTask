//
//  ObjCNetworkPerformer.h
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Domain used to describe Objective-C bridge errors that require Swift-side mapping.
FOUNDATION_EXPORT NSString * const ObjCNetworkErrorDomain;
/// Key used to expose HTTP status codes through NSError userInfo.
FOUNDATION_EXPORT NSString * const ObjCNetworkStatusCodeKey;
/// Key used to expose HTTP response payloads through NSError userInfo.
FOUNDATION_EXPORT NSString * const ObjCNetworkResponseDataKey;

/// Completion block called by the Objective-C performer once the request finishes.
typedef void (^ObjCNetworkCompletion)(NSData * _Nullable data,
                                      NSURLResponse * _Nullable response,
                                      NSError * _Nullable error);

/// Responsible for executing URL requests on a dedicated NSURLSession and reporting completion back to Swift.
@interface ObjCNetworkPerformer : NSObject

/// Creates a performer backed by a custom session.
/// @param session Session used to execute all URL requests. Ownership is not transferred.
- (instancetype)initWithSession:(NSURLSession *)session NS_DESIGNATED_INITIALIZER;

/// Creates a performer backed by `URLSession.shared`.
- (instancetype)init;

/// Executes the request and routes the response through the completion block.
/// @param request A fully-prepared request coming from Swift transport layers.
/// @param completion Completion block that receives either the response or the mapped error.
- (void)performRequest:(NSURLRequest *)request
            completion:(ObjCNetworkCompletion)completion NS_SWIFT_NAME(performRequest(_:completion:));

@end

NS_ASSUME_NONNULL_END

