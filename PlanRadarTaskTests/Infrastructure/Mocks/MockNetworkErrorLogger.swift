//
//  MockNetworkErrorLogger.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of NetworkErrorLogger for testing.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockNetworkErrorLogger: NetworkErrorLogger {
    
    /// Tracks if log request was called
    var logRequestCalled = false
    
    /// The request that was logged
    var loggedRequest: URLRequest?
    
    /// Tracks if log response was called
    var logResponseCalled = false
    
    /// The response data that was logged
    var loggedResponseData: Data?
    
    /// The response that was logged
    var loggedResponse: URLResponse?
    
    /// Tracks if log error was called
    var logErrorCalled = false
    
    /// The error that was logged
    var loggedError: Error?
    
    func log(request: URLRequest) {
        logRequestCalled = true
        loggedRequest = request
    }
    
    func log(responseData data: Data?, response: URLResponse?) {
        logResponseCalled = true
        loggedResponseData = data
        loggedResponse = response
    }
    
    func log(error: Error) {
        logErrorCalled = true
        loggedError = error
    }
}

