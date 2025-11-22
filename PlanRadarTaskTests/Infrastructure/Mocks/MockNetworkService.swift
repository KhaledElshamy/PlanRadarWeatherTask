//
//  MockNetworkService.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of NetworkService for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
/// However, properties are marked as nonisolated for clarity.
///
/// **Memory Management:** No retain cycles - endpoint is stored as a value type reference.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockNetworkService: NetworkService {
    
    /// Serial queue for thread-safe property access (if needed for concurrent tests)
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.networkservice")
    
    /// The data to return on successful requests
    private var _dataToReturn: Data?
    var dataToReturn: Data? {
        get { accessQueue.sync { _dataToReturn } }
        set { accessQueue.sync { _dataToReturn = newValue } }
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
    private var _requestedEndpoint: Requestable?
    var requestedEndpoint: Requestable? {
        get { accessQueue.sync { _requestedEndpoint } }
        set { accessQueue.sync { _requestedEndpoint = newValue } }
    }
    
    /// Initializes the mock with optional return values.
    ///
    /// - Parameters:
    ///   - dataToReturn: Data to return on success (default: nil)
    ///   - errorToThrow: Error to throw on failure (default: nil)
    init(dataToReturn: Data? = nil, errorToThrow: Error? = nil) {
        self._dataToReturn = dataToReturn
        self._errorToThrow = errorToThrow
    }
    
    func request(endpoint: Requestable) async throws -> Data? {
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
        
        let data = accessQueue.sync { _dataToReturn }
        return data
    }
}

