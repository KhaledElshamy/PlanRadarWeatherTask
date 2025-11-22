//
//  MockFetchWeatherIconUseCase.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of FetchWeatherIconUseCase for testing.
///
/// **Thread Safety:** Properties are accessed from async test methods,
/// but since tests run sequentially, no additional synchronization is needed.
///
/// **Memory Management:** No retain cycles - data is stored as value type.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockFetchWeatherIconUseCase: FetchWeatherIconUseCaseProtocol {
    
    /// Serial queue for thread-safe property access
    private let accessQueue = DispatchQueue(label: "com.planradartask.mock.fetchweathericonusecase")
    
    /// Image data to return on execute
    private var _imageDataToReturn: Data?
    var imageDataToReturn: Data? {
        get { accessQueue.sync { _imageDataToReturn } }
        set { accessQueue.sync { _imageDataToReturn = newValue } }
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
    
    /// Tracks the icon code that was executed
    private var _executedIconCode: String?
    var executedIconCode: String? {
        get { accessQueue.sync { _executedIconCode } }
        set { accessQueue.sync { _executedIconCode = newValue } }
    }
    
    /// Resets all mock state
    func reset() {
        accessQueue.sync {
            _imageDataToReturn = nil
            _fetchError = nil
            _executeCalled = false
            _executedIconCode = nil
        }
    }
    
    func execute(iconCode: String) async throws -> Data {
        executeCalled = true
        executedIconCode = iconCode
        if let error = fetchError {
            throw error
        }
        guard let data = imageDataToReturn else {
            throw NSError(domain: "MockFetchWeatherIconUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "No image data set in mock"])
        }
        return data
    }
}

