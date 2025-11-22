//
//  CitiesViewModelTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
import Combine
@testable import PlanRadarTask

/// Unit tests for CitiesViewModel.
///
/// **Specification Interpretation:**
/// These tests verify that CitiesViewModel correctly manages state, handles user actions,
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
final class CitiesViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: CitiesViewModel!
    private var mockFetchUseCase: MockFetchCitiesUseCase!
    private var mockDeleteUseCase: MockDeleteCityUseCase!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchCitiesUseCase()
        mockDeleteUseCase = MockDeleteCityUseCase()
        cancellables = Set<AnyCancellable>()
        
        viewModel = CitiesViewModel(
            fetchUseCase: mockFetchUseCase,
            deleteUseCase: mockDeleteUseCase
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockFetchUseCase = nil
        mockDeleteUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    /// Tests that cities are automatically loaded on initialization.
    func testInit_AutomaticallyLoadsCities() async {
        // Given
        let expectedCities = CityFactory.makeCities(count: 2)
        mockFetchUseCase.citiesToReturn = expectedCities
        
        // Wait for async initialization to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(mockFetchUseCase.executeCalled)
    }
    
    // MARK: - Load Cities Tests
    
    /// Tests successful loading of cities.
    func testLoadCities_Success_UpdatesCitiesList() async {
        // Given
        let expectedCities = CityFactory.makeCities(count: 3)
        mockFetchUseCase.citiesToReturn = expectedCities
        
        // When
        viewModel.loadCitiesSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.citiesList, expectedCities)
        XCTAssertTrue(mockFetchUseCase.executeCalled)
        XCTAssertFalse(viewModel.isLoadingState)
        XCTAssertNil(viewModel.errorMessageText)
    }
    
    /// Tests loading cities with error.
    func testLoadCities_Failure_SetsErrorMessage() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        mockFetchUseCase.fetchError = expectedError
        
        // When
        viewModel.loadCitiesSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(viewModel.citiesList.isEmpty)
        XCTAssertTrue(mockFetchUseCase.executeCalled)
        XCTAssertFalse(viewModel.isLoadingState)
        XCTAssertEqual(viewModel.errorMessageText, "Test error message")
    }
    
    /// Tests loading cities sets loading state correctly.
    func testLoadCities_SetsLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        viewModel.isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadCitiesSubject.send()
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(loadingStates.contains(true), "Should set loading to true")
        XCTAssertTrue(loadingStates.contains(false), "Should set loading to false")
    }
    
    // MARK: - Delete City Tests
    
    /// Tests successful deletion of a city.
    func testDeleteCity_Success_RemovesCityAndRefreshes() async {
        // Given
        let cities = CityFactory.makeCities(count: 3)
        mockFetchUseCase.citiesToReturn = cities
        
        // Load cities first
        viewModel.loadCitiesSubject.send()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When - delete city at index 1
        viewModel.deleteCitySubject.send(IndexSet(integer: 1))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockDeleteUseCase.executeCalled)
        XCTAssertEqual(mockDeleteUseCase.deletedCity, cities[1])
        // Should refresh after deletion
        XCTAssertTrue(mockFetchUseCase.executeCallCount >= 2)
    }
    
    /// Tests deletion with error.
    func testDeleteCity_Failure_SetsErrorMessage() async {
        // Given
        let cities = CityFactory.makeCities(count: 2)
        mockFetchUseCase.citiesToReturn = cities
        let expectedError = NSError(domain: "TestError", code: 456, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        mockDeleteUseCase.deleteError = expectedError
        
        // Load cities first
        viewModel.loadCitiesSubject.send()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When
        viewModel.deleteCitySubject.send(IndexSet(integer: 0))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockDeleteUseCase.executeCalled)
        XCTAssertEqual(viewModel.errorMessageText, "Delete failed")
    }
    
    /// Tests deletion with invalid index does nothing.
    func testDeleteCity_InvalidIndex_DoesNothing() async {
        // Given
        let cities = CityFactory.makeCities(count: 2)
        mockFetchUseCase.citiesToReturn = cities
        
        // Load cities first
        viewModel.loadCitiesSubject.send()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let initialCallCount = mockDeleteUseCase.executeCallCount
        
        // When - delete at invalid index
        viewModel.deleteCitySubject.send(IndexSet(integer: 999))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockDeleteUseCase.executeCallCount, initialCallCount, "Should not call delete for invalid index")
    }
    
    // MARK: - Retry Tests
    
    /// Tests retry after error reloads cities.
    func testRetry_ReloadsCities() async {
        // Given
        let expectedCities = CityFactory.makeCities(count: 2)
        mockFetchUseCase.citiesToReturn = expectedCities
        
        // When
        viewModel.retrySubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockFetchUseCase.executeCalled)
        XCTAssertEqual(viewModel.citiesList, expectedCities)
    }
    
    // MARK: - Publisher Tests
    
    /// Tests cities publisher emits updates.
    func testCitiesPublisher_EmitsUpdates() async {
        // Given
        let expectation = XCTestExpectation(description: "Cities publisher emits")
        var receivedCities: [City] = []
        
        viewModel.cities
            .sink { cities in
                receivedCities.append(contentsOf: cities)
                if !cities.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let expectedCities = CityFactory.makeCities(count: 2)
        mockFetchUseCase.citiesToReturn = expectedCities
        
        // When
        viewModel.loadCitiesSubject.send()
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertFalse(receivedCities.isEmpty)
    }
    
    /// Tests isEmpty publisher reflects cities list state.
    func testIsEmptyPublisher_ReflectsState() async {
        // Given
        let expectation = XCTestExpectation(description: "IsEmpty publisher emits")
        var isEmptyStates: [Bool] = []
        
        viewModel.isEmpty
            .sink { isEmpty in
                isEmptyStates.append(isEmpty)
                if isEmptyStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - load empty list
        mockFetchUseCase.citiesToReturn = []
        viewModel.loadCitiesSubject.send()
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(isEmptyStates.contains(true), "Should emit true when list is empty")
    }
    
    /// Tests errorMessage publisher emits error messages.
    func testErrorMessagePublisher_EmitsErrors() async {
        // Given
        let expectation = XCTestExpectation(description: "ErrorMessage publisher emits")
        var errorMessages: [String?] = []
        
        viewModel.errorMessage
            .sink { message in
                errorMessages.append(message)
                if message != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockFetchUseCase.fetchError = expectedError
        
        // When
        viewModel.loadCitiesSubject.send()
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(errorMessages.contains("Test error"), "Should emit error message")
    }
}

