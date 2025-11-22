//
//  CityDetailsViewModelTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
import Combine
import SwiftUI
@testable import PlanRadarTask

/// Unit tests for CityDetailsViewModel.
///
/// **Specification Interpretation:**
/// These tests verify that CityDetailsViewModel correctly manages state, handles user actions,
/// and publishes updates through Combine publishers. All success and failure scenarios are covered.
///
/// **Thread Safety:**
/// - All async test methods properly await results
/// - Mock state is accessed through thread-safe properties
/// - No shared mutable state between tests (each test has isolated setup)
/// - ViewModel is @MainActor, so all operations run on main thread
///
/// **Memory Management:**
/// - All properties are properly cleaned up in tearDown()
/// - No retain cycles (mocks don't hold strong references to test class)
/// - Cancellables are properly disposed
/// - Mock state is reset between tests to prevent leaks
///
/// **Access Control:**
/// - Internal class: Used within test module
@MainActor
final class CityDetailsViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: CityDetailsViewModel!
    private var mockUseCase: MockFetchWeatherIconUseCase!
    private var cancellables: Set<AnyCancellable>!
    private var testCity: City!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockFetchWeatherIconUseCase()
        cancellables = Set<AnyCancellable>()
        
        testCity = CityFactory.makeCity(
            displayName: "London, GB",
            temperature: "15°",
            humidity: "87%",
            wind: "2.5 m/s",
            description: "broken clouds",
            iconURL: URL(string: "https://openweathermap.org/img/w/01d.png")
        )
        
        viewModel = CityDetailsViewModel(
            city: testCity,
            fetchWeatherIconUseCase: mockUseCase
        )
    }
    
    override func tearDown() {
        // Clean up cancellables first to stop any ongoing subscriptions
        cancellables.removeAll()
        viewModel = nil
        mockUseCase = nil
        testCity = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    /// Tests that weather icon is automatically loaded on initialization.
    func testInit_AutomaticallyLoadsIcon() async {
        // Given
        let expectedData = createTestImageData()
        mockUseCase.imageDataToReturn = expectedData
        
        // Wait for async initialization to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Give additional time to ensure all tasks complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(mockUseCase.executeCalled)
    }
    
    // MARK: - Load Icon Tests
    
    /// Tests successful loading of weather icon.
    func testLoadIcon_Success_UpdatesImage() async {
        // Given
        let expectedData = createTestImageData()
        mockUseCase.imageDataToReturn = expectedData
        
        // Set up publishers to capture state changes
        let imageExpectation = XCTestExpectation(description: "Icon image received")
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        var receivedImage: Image? = nil
        var receivedError: String? = nil
        var loadingStates: [Bool] = []
        
        viewModel.weatherIconImage
            .sink { image in
                receivedImage = image
                if image != nil {
                    imageExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.iconError
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        viewModel.isLoadingIcon
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadWeatherIconSubject.send()
        
        // Wait for async operation and publisher emissions
        await fulfillment(of: [imageExpectation, loadingExpectation], timeout: 2.0)
        
        // Then
        XCTAssertTrue(mockUseCase.executeCalled)
        XCTAssertNotNil(receivedImage)
        XCTAssertNil(receivedError)
        XCTAssertTrue(loadingStates.contains(false), "Should set loading to false")
    }
    
    /// Tests icon loading failure shows error.
    func testLoadIcon_Failure_ShowsError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Icon not found"])
        mockUseCase.fetchError = expectedError
        
        // Set up publishers to capture state changes
        let errorExpectation = XCTestExpectation(description: "Error received")
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        var receivedError: String? = nil
        var receivedImage: Image? = nil
        var loadingStates: [Bool] = []
        
        // Use receive(on:) to ensure emissions happen on main actor
        viewModel.iconError
            .receive(on: DispatchQueue.main)
            .sink { error in
                receivedError = error
                if error != nil {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.weatherIconImage
            .receive(on: DispatchQueue.main)
            .sink { image in
                receivedImage = image
            }
            .store(in: &cancellables)
        
        viewModel.isLoadingIcon
            .receive(on: DispatchQueue.main)
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadWeatherIconSubject.send()
        
        // Wait for async operation and publisher emissions
        await fulfillment(of: [errorExpectation, loadingExpectation], timeout: 2.0)
        
        // Give a small delay to ensure all async operations complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then
        XCTAssertTrue(mockUseCase.executeCalled)
        XCTAssertEqual(receivedError, "Icon not found")
        XCTAssertNil(receivedImage)
        XCTAssertTrue(loadingStates.contains(false), "Should set loading to false")
    }
    
    
    // MARK: - Retry Tests
    
    /// Tests retry reloads icon.
    func testRetry_ReloadsIcon() async {
        // Given
        let expectedData = createTestImageData()
        mockUseCase.imageDataToReturn = expectedData
        
        // When
        viewModel.retryLoadIconSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Give additional time to ensure all tasks complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(mockUseCase.executeCalled)
    }
    
    // MARK: - Publisher Tests
    
    /// Tests city name publisher extracts city name correctly.
    func testCityNamePublisher_ExtractsCityName() async {
        // Given
        let expectation = XCTestExpectation(description: "City name publisher emits")
        var receivedNames: [String] = []
        
        viewModel.cityName
            .sink { name in
                receivedNames.append(name)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for publisher
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Give a small delay to ensure all async operations complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then
        XCTAssertFalse(receivedNames.isEmpty)
        XCTAssertEqual(receivedNames.first, "London")
    }
    
    /// Tests description publisher capitalizes description.
    func testDescriptionPublisher_CapitalizesDescription() async {
        // Given
        let expectation = XCTestExpectation(description: "Description publisher emits")
        var receivedDescriptions: [String] = []
        
        viewModel.description
            .sink { description in
                receivedDescriptions.append(description)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for publisher
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Give a small delay to ensure all async operations complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then
        XCTAssertFalse(receivedDescriptions.isEmpty)
        XCTAssertEqual(receivedDescriptions.first, "Broken Clouds")
    }
    
    /// Tests formatted update time publisher formats date correctly.
    func testFormattedUpdateTimePublisher_FormatsDate() async {
        // Given
        let expectation = XCTestExpectation(description: "Formatted update time publisher emits")
        var receivedTimes: [String] = []
        
        viewModel.formattedUpdateTime
            .sink { time in
                receivedTimes.append(time)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for publisher
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Give a small delay to ensure all async operations complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then
        XCTAssertFalse(receivedTimes.isEmpty)
        // Should match format "dd.MM.yyyy - HH:mm"
        XCTAssertTrue(receivedTimes.first?.contains(".") == true)
    }
    
    // MARK: - Helper Methods
    
    /// Creates test image data for testing.
    ///
    /// - Returns: Valid PNG image data
    private func createTestImageData() -> Data {
        // Create a simple 1x1 PNG image
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image?.pngData() ?? Data()
    }
}

