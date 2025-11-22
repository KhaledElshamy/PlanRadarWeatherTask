//
//  MockFetchCityHistoryUseCase.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of FetchCityHistoryUseCase for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - entries are stored as value types.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockFetchCityHistoryUseCase: FetchCityHistoryUseCaseProtocol {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.fetchcityhistoryusecase")
    
    /// Entries to return on execute
    private var _entriesToReturn: [CityHistoryEntry] = []
    var entriesToReturn: [CityHistoryEntry] {
        get { accessQueue.sync { _entriesToReturn } }
        set { accessQueue.sync { _entriesToReturn = newValue } }
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
    
    /// Tracks the city name that was executed
    private var _executedCityName: String?
    var executedCityName: String? {
        get { accessQueue.sync { _executedCityName } }
        set { accessQueue.sync { _executedCityName = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _entriesToReturn = []
            _fetchError = nil
            _executeCalled = false
            _executedCityName = nil
        }
    }
    
    func execute(cityName: String) async throws -> [CityHistoryEntry] {
        executeCalled = true
        executedCityName = cityName
        if let error = fetchError {
            throw error
        }
        return entriesToReturn
    }
}
