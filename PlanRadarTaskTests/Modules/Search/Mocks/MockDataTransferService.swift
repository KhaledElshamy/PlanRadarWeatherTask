//
//  MockDataTransferService.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of DataTransferService for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - response is stored as a value type reference.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockDataTransferService: DataTransferService {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.datatransferservice")
    
    /// The response to return on successful requests
    private var _responseToReturn: Any?
    var responseToReturn: Any? {
        get { accessQueue.sync { _responseToReturn } }
        set { accessQueue.sync { _responseToReturn = newValue } }
    }
    
    /// The error to throw on failed requests
    private var _errorToThrow: Error?
    var errorToThrow: Error? {
        get { accessQueue.sync { _errorToThrow } }
        set { accessQueue.sync { _errorToThrow = newValue } }
    }
    
    /// Tracks if request was called
    private var _requestCalled = false
    var requestCalled: Bool {
        get { accessQueue.sync { _requestCalled } }
        set { accessQueue.sync { _requestCalled = newValue } }
    }
    
    /// The endpoint that was requested
    private var _requestedEndpoint: ResponseRequestable?
    var requestedEndpoint: ResponseRequestable? {
        get { accessQueue.sync { _requestedEndpoint } }
        set { accessQueue.sync { _requestedEndpoint = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _responseToReturn = nil
            _errorToThrow = nil
            _requestCalled = false
            _requestedEndpoint = nil
        }
    }
    
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E
    ) async throws -> T where E.Response == T {
        // Thread-safe state update
        accessQueue.sync {
            _requestCalled = true
            _requestedEndpoint = endpoint
        }
        
        // Thread-safe state read
        let error = accessQueue.sync { _errorToThrow }
        if let error = error {
            throw error
        }
        
        guard let response = accessQueue.sync(execute: { _responseToReturn }) as? T else {
            throw NSError(domain: "MockDataTransferService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response set in mock"])
        }
        
        return response
    }
    
    func request<E: ResponseRequestable>(
        with endpoint: E
    ) async throws where E.Response == Void {
        // Thread-safe state update
        accessQueue.sync {
            _requestCalled = true
            _requestedEndpoint = endpoint
        }
        
        // Thread-safe state read
        let error = accessQueue.sync { _errorToThrow }
        if let error = error {
            throw error
        }
        
        // For Void responses, we just return without a value
    }
}

