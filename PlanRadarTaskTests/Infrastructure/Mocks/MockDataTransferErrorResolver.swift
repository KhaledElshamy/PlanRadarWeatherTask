//
//  MockDataTransferErrorResolver.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of DataTransferErrorResolver for testing.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockDataTransferErrorResolver: DataTransferErrorResolver {
    
    /// The error to return when resolving
    var resolvedError: Error?
    
    /// Tracks if resolve was called
    var resolveCalled = false
    
    /// The error that was passed to resolve
    var resolvedNetworkError: NetworkError?
    
    /// Initializes the mock.
    ///
    /// - Parameter resolvedError: Error to return when resolving (default: nil, returns original error)
    init(resolvedError: Error? = nil) {
        self.resolvedError = resolvedError
    }
    
    func resolve(error: NetworkError) -> Error {
        resolveCalled = true
        resolvedNetworkError = error
        
        if let resolvedError = resolvedError {
            return resolvedError
        }
        
        return error
    }
}

