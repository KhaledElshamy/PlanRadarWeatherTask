//
//  MockCitiesRepository.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of CitiesRepository for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - cities are stored as value types.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockCitiesRepository: CitiesRepository {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.citiesrepository")
    
    /// Cities to return on fetchSavedCities
    private var _citiesToReturn: [City] = []
    var citiesToReturn: [City] {
        get { accessQueue.sync { _citiesToReturn } }
        set { accessQueue.sync { _citiesToReturn = newValue } }
    }
    
    /// Error to throw on fetchSavedCities
    private var _fetchError: Error?
    var fetchError: Error? {
        get { accessQueue.sync { _fetchError } }
        set { accessQueue.sync { _fetchError = newValue } }
    }
    
    /// Error to throw on delete
    private var _deleteError: Error?
    var deleteError: Error? {
        get { accessQueue.sync { _deleteError } }
        set { accessQueue.sync { _deleteError = newValue } }
    }
    
    /// Tracks if fetchSavedCities was called
    private var _fetchCalled = false
    var fetchCalled: Bool {
        get { accessQueue.sync { _fetchCalled } }
        set { accessQueue.sync { _fetchCalled = newValue } }
    }
    
    /// Tracks if delete was called
    private var _deleteCalled = false
    var deleteCalled: Bool {
        get { accessQueue.sync { _deleteCalled } }
        set { accessQueue.sync { _deleteCalled = newValue } }
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
            _citiesToReturn = []
            _fetchError = nil
            _deleteError = nil
            _fetchCalled = false
            _deleteCalled = false
            _deletedCity = nil
        }
    }
    
    func fetchSavedCities() async throws -> [City] {
        fetchCalled = true
        if let error = fetchError {
            throw error
        }
        return citiesToReturn
    }
    
    func delete(_ city: City) async throws {
        deleteCalled = true
        deletedCity = city
        if let error = deleteError {
            throw error
        }
    }
}

