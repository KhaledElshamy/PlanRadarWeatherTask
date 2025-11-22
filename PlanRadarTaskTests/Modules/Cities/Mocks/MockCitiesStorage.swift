//
//  MockCitiesStorage.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of CitiesStorage for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - cities are stored as value types.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockCitiesStorage: CitiesStorage {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.citiesstorage")
    
    /// Cities to return on fetch
    private var _citiesToReturn: [City] = []
    var citiesToReturn: [City] {
        get { accessQueue.sync { _citiesToReturn } }
        set { accessQueue.sync { _citiesToReturn = newValue } }
    }
    
    /// Error to throw on fetch
    private var _fetchError: Error?
    var fetchError: Error? {
        get { accessQueue.sync { _fetchError } }
        set { accessQueue.sync { _fetchError = newValue } }
    }
    
    /// Error to throw on save
    private var _saveError: Error?
    var saveError: Error? {
        get { accessQueue.sync { _saveError } }
        set { accessQueue.sync { _saveError = newValue } }
    }
    
    /// Error to throw on delete
    private var _deleteError: Error?
    var deleteError: Error? {
        get { accessQueue.sync { _deleteError } }
        set { accessQueue.sync { _deleteError = newValue } }
    }
    
    /// Tracks if fetchCities was called
    private var _fetchCalled = false
    var fetchCalled: Bool {
        get { accessQueue.sync { _fetchCalled } }
        set { accessQueue.sync { _fetchCalled = newValue } }
    }
    
    /// Tracks if save was called
    private var _saveCalled = false
    var saveCalled: Bool {
        get { accessQueue.sync { _saveCalled } }
        set { accessQueue.sync { _saveCalled = newValue } }
    }
    
    /// Tracks the city that was saved
    private var _savedCity: City?
    var savedCity: City? {
        get { accessQueue.sync { _savedCity } }
        set { accessQueue.sync { _savedCity = newValue } }
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
            _saveError = nil
            _deleteError = nil
            _fetchCalled = false
            _saveCalled = false
            _savedCity = nil
            _deleteCalled = false
            _deletedCity = nil
        }
    }
    
    func fetchCities() async throws -> [City] {
        fetchCalled = true
        if let error = fetchError {
            throw error
        }
        return citiesToReturn
    }
    
    func save(_ city: City) async throws {
        saveCalled = true
        savedCity = city
        if let error = saveError {
            throw error
        }
    }
    
    func delete(_ city: City) async throws {
        deleteCalled = true
        deletedCity = city
        if let error = deleteError {
            throw error
        }
    }
}

