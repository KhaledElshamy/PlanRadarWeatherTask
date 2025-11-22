//
//  MockSearchCityUseCase.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of SearchCityUseCase for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - city is stored as value type.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockSearchCityUseCase: SearchCityUseCaseProtocol {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.searchcityusecase")
    
    /// City to return on execute
    private var _cityToReturn: City?
    var cityToReturn: City? {
        get { accessQueue.sync { _cityToReturn } }
        set { accessQueue.sync { _cityToReturn = newValue } }
    }
    
    /// Error to throw on execute
    private var _searchError: Error?
    var searchError: Error? {
        get { accessQueue.sync { _searchError } }
        set { accessQueue.sync { _searchError = newValue } }
    }
    
    /// Tracks if execute was called
    private var _executeCalled = false
    var executeCalled: Bool {
        get { accessQueue.sync { _executeCalled } }
        set { accessQueue.sync { _executeCalled = newValue } }
    }
    
    /// Tracks the query that was executed
    private var _executedQuery: String?
    var executedQuery: String? {
        get { accessQueue.sync { _executedQuery } }
        set { accessQueue.sync { _executedQuery = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _cityToReturn = nil
            _searchError = nil
            _executeCalled = false
            _executedQuery = nil
        }
    }
    
    func execute(query: String) async throws -> City {
        executeCalled = true
        executedQuery = query
        if let error = searchError {
            throw error
        }
        guard let city = cityToReturn else {
            throw NSError(domain: "MockSearchCityUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "No city set in mock"])
        }
        return city
    }
}

