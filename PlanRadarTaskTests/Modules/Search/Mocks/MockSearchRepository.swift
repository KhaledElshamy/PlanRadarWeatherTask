//
//  MockSearchRepository.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of SearchRepository for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - city is stored as value type.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockSearchRepository: SearchRepository {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.searchrepository")
    
    /// City to return on searchCity
    private var _cityToReturn: City?
    var cityToReturn: City? {
        get { accessQueue.sync { _cityToReturn } }
        set { accessQueue.sync { _cityToReturn = newValue } }
    }
    
    /// Error to throw on searchCity
    private var _searchError: Error?
    var searchError: Error? {
        get { accessQueue.sync { _searchError } }
        set { accessQueue.sync { _searchError = newValue } }
    }
    
    /// Tracks if searchCity was called
    private var _searchCalled = false
    var searchCalled: Bool {
        get { accessQueue.sync { _searchCalled } }
        set { accessQueue.sync { _searchCalled = newValue } }
    }
    
    /// Tracks the query that was searched
    private var _searchedQuery: String?
    var searchedQuery: String? {
        get { accessQueue.sync { _searchedQuery } }
        set { accessQueue.sync { _searchedQuery = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _cityToReturn = nil
            _searchError = nil
            _searchCalled = false
            _searchedQuery = nil
        }
    }
    
    func searchCity(named name: String) async throws -> City {
        searchCalled = true
        searchedQuery = name
        if let error = searchError {
            throw error
        }
        guard let city = cityToReturn else {
            throw NSError(domain: "MockSearchRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No city set in mock"])
        }
        return city
    }
}

