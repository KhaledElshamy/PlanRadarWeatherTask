//
//  MockFetchCitiesUseCase.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of FetchCitiesUseCase for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - cities are stored as value types.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockFetchCitiesUseCase: FetchCitiesUseCaseProtocol {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.fetchcitiesusecase")
    
    /// Cities to return on execute
    private var _citiesToReturn: [City] = []
    var citiesToReturn: [City] {
        get { accessQueue.sync { _citiesToReturn } }
        set { accessQueue.sync { _citiesToReturn = newValue } }
    }
    
    /// Error to throw on execute
    private var _fetchError: Error?
    var fetchError: Error? {
        get { accessQueue.sync { _fetchError } }
        set { accessQueue.sync { _fetchError = newValue } }
    }
    
    /// Tracks if execute was called
    private var _executeCalled = false
    var executeCalled: Bool {
        get { accessQueue.sync { _executeCalled } }
        set { accessQueue.sync { _executeCalled = newValue } }
    }
    
    /// Tracks number of times execute was called
    private var _executeCallCount = 0
    var executeCallCount: Int {
        get { accessQueue.sync { _executeCallCount } }
        set { accessQueue.sync { _executeCallCount = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _citiesToReturn = []
            _fetchError = nil
            _executeCalled = false
            _executeCallCount = 0
        }
    }
    
    func execute() async throws -> [City] {
        executeCalled = true
        executeCallCount += 1
        if let error = fetchError {
            throw error
        }
        return citiesToReturn
    }
}

