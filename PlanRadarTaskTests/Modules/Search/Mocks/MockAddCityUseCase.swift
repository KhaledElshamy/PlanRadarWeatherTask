//
//  MockAddCityUseCase.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of AddCityUseCase for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - city is stored as value type.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockAddCityUseCase: AddCityUseCaseProtocol {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.addcityusecase")
    
    /// Error to throw on execute
    private var _addError: Error?
    var addError: Error? {
        get { accessQueue.sync { _addError } }
        set { accessQueue.sync { _addError = newValue } }
    }
    
    /// Tracks if execute was called
    private var _executeCalled = false
    var executeCalled: Bool {
        get { accessQueue.sync { _executeCalled } }
        set { accessQueue.sync { _executeCalled = newValue } }
    }
    
    /// Tracks the city that was added
    private var _addedCity: City?
    var addedCity: City? {
        get { accessQueue.sync { _addedCity } }
        set { accessQueue.sync { _addedCity = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _addError = nil
            _executeCalled = false
            _addedCity = nil
        }
    }
    
    func execute(city: City) async throws {
        executeCalled = true
        addedCity = city
        if let error = addError {
            throw error
        }
    }
}

