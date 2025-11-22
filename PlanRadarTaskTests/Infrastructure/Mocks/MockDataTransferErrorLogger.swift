//
//  MockDataTransferErrorLogger.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of DataTransferErrorLogger for testing.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockDataTransferErrorLogger: DataTransferErrorLogger {
    
    /// Tracks if log was called
    var logCalled = false
    
    /// The error that was logged
    var loggedError: Error?
    
    /// Number of times log was called
    var logCallCount = 0
    
    func log(error: Error) {
        logCalled = true
        loggedError = error
        logCallCount += 1
    }
}

