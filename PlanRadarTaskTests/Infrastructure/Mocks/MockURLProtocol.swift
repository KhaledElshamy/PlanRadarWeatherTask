//
//  MockURLProtocol.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation

/// URLProtocol subclass for intercepting network requests in tests.
///
/// **Note:** This protocol intercepts network calls at the URLSession level,
/// allowing us to test Swift code without mocking Objective-C classes.
///
/// **Thread Safety:** Handler is accessed from URLSession's background queue,
/// so we use thread-safe access patterns.
///
/// **Memory Management:** Handler is a static property, so it doesn't create
/// retain cycles. It's cleared in reset() to prevent memory leaks.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockURLProtocol: URLProtocol {
    
    /// Serial queue for thread-safe handler access
    private static let handlerQueue = DispatchQueue(label: "com.planradartask.mock.urlprotocol.handler")
    
    /// Handler for processing requests (thread-safe)
    private static var _requestHandler: ((URLRequest) throws -> (Data?, URLResponse?))?
    
    static var requestHandler: ((URLRequest) throws -> (Data?, URLResponse?))? {
        get { handlerQueue.sync { _requestHandler } }
        set { handlerQueue.sync { _requestHandler = newValue } }
    }
    
    /// Tracks if a request was intercepted
    private static var _lastRequest: URLRequest?
    
    static var lastRequest: URLRequest? {
        get { handlerQueue.sync { _lastRequest } }
        set { handlerQueue.sync { _lastRequest = newValue } }
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return handlerQueue.sync { _requestHandler != nil }
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        // Thread-safe handler access
        let handler = Self.handlerQueue.sync { Self._requestHandler }
        
        guard let handler = handler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
            return
        }
        
        // Track the request
        Self.handlerQueue.sync {
            Self._lastRequest = request
        }
        
        do {
            let (data, response) = try handler(request)
            
            // Use weak self pattern to avoid retain cycles with client
            guard let client = self.client else { return }
            
            if let response = response {
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                client.urlProtocol(self, didLoad: data)
            }
            
            client.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // Clean up any ongoing operations
        // No-op for mock, but ensures proper protocol compliance
    }
    
    /// Resets the protocol state.
    static func reset() {
        handlerQueue.sync {
            _requestHandler = nil
            _lastRequest = nil
        }
    }
}

