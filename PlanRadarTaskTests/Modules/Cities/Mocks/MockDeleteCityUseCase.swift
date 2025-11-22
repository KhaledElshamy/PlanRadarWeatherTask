//
//  MockDeleteCityUseCase.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of DeleteCityUseCase for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - city is stored as value type.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockDeleteCityUseCase: DeleteCityUseCaseProtocol {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.deletecityusecase")
    
    /// Error to throw on execute
    private var _deleteError: Error?
    var deleteError: Error? {
        get { accessQueue.sync { _deleteError } }
        set { accessQueue.sync { _deleteError = newValue } }
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
    
    /// Tracks the city that was deleted
    private var _deletedCity: City?
    var deletedCity: City? {
        get { accessQueue.sync { _deletedCity } }
        set { accessQueue.sync { _deletedCity = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _deleteError = nil
            _executeCalled = false
            _executeCallCount = 0
            _deletedCity = nil
        }
    }
    
    func execute(city: City) async throws {
        executeCalled = true
        executeCallCount += 1
        deletedCity = city
        if let error = deleteError {
            throw error
        }
    }
}

