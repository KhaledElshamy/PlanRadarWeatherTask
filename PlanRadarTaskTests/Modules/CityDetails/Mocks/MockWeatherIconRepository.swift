//
//  MockWeatherIconRepository.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of WeatherIconRepository for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - data is stored as value type.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockWeatherIconRepository: WeatherIconRepository {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.weathericonrepository")
    
    /// Image data to return on fetchWeatherIcon
    private var _imageDataToReturn: Data?
    var imageDataToReturn: Data? {
        get { accessQueue.sync { _imageDataToReturn } }
        set { accessQueue.sync { _imageDataToReturn = newValue } }
    }
    
    /// Error to throw on fetchWeatherIcon
    private var _fetchError: Error?
    var fetchError: Error? {
        get { accessQueue.sync { _fetchError } }
        set { accessQueue.sync { _fetchError = newValue } }
    }
    
    /// Tracks if fetchWeatherIcon was called
    private var _fetchCalled = false
    var fetchCalled: Bool {
        get { accessQueue.sync { _fetchCalled } }
        set { accessQueue.sync { _fetchCalled = newValue } }
    }
    
    /// Tracks the icon code that was fetched
    private var _fetchedIconCode: String?
    var fetchedIconCode: String? {
        get { accessQueue.sync { _fetchedIconCode } }
        set { accessQueue.sync { _fetchedIconCode = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _imageDataToReturn = nil
            _fetchError = nil
            _fetchCalled = false
            _fetchedIconCode = nil
        }
    }
    
    func fetchWeatherIcon(iconCode: String) async throws -> Data {
        fetchCalled = true
        fetchedIconCode = iconCode
        if let error = fetchError {
            throw error
        }
        guard let data = imageDataToReturn else {
            throw NSError(domain: "MockWeatherIconRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No image data set in mock"])
        }
        return data
    }
}

