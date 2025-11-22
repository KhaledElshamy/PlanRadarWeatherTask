//
//  SearchViewModelTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
import Combine
@testable import PlanRadarTask

/// Unit tests for SearchViewModel.
///
/// **Specification Interpretation:**
/// These tests verify that SearchViewModel correctly manages state, handles user actions,
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
final class SearchViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: SearchViewModel!
    private var mockSearchUseCase: MockSearchCityUseCase!
    private var mockAddUseCase: MockAddCityUseCase!
    private var cancellables: Set<AnyCancellable>!
    private var completionCalled: Bool!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockSearchUseCase = MockSearchCityUseCase()
        mockAddUseCase = MockAddCityUseCase()
        cancellables = Set<AnyCancellable>()
        completionCalled = false
        
        viewModel = SearchViewModel(
            searchUseCase: mockSearchUseCase,
            addUseCase: mockAddUseCase,
            completion: { [weak self] in
                self?.completionCalled = true
            }
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockSearchUseCase = nil
        mockAddUseCase = nil
        completionCalled = nil
        super.tearDown()
    }
    
    // MARK: - Query Tests
    
    /// Tests query subject updates query value.
    func testQuerySubject_UpdatesQuery() async {
        // Given
        let testQuery = "London"
        
        // When
        viewModel.querySubject.send(testQuery)
        
        // Wait for async update
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Then
        XCTAssertEqual(viewModel.queryText, testQuery)
    }
    
    /// Tests clear query subject clears query and error.
    func testClearQuerySubject_ClearsQueryAndError() async {
        // Given
        viewModel.querySubject.send("London")
        viewModel.queryText = "London" // Set directly for testing
        
        // When
        viewModel.clearQuerySubject.send()
        
        // Wait for async update
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Then
        XCTAssertTrue(viewModel.queryText.isEmpty)
        XCTAssertNil(viewModel.errorMessageText)
        XCTAssertNil(viewModel.latestSearchResult)
    }
    
    // MARK: - Search Tests
    
    /// Tests successful search and add.
    func testSubmit_Success_SearchesAndAddsCity() async {
        // Given
        let city = CityFactory.makeCity(displayName: "London, GB")
        mockSearchUseCase.cityToReturn = city
        viewModel.queryText = "London"
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(mockSearchUseCase.executeCalled)
        XCTAssertEqual(mockSearchUseCase.executedQuery, "London")
        XCTAssertTrue(mockAddUseCase.executeCalled)
        XCTAssertEqual(mockAddUseCase.addedCity, city)
        XCTAssertNotNil(viewModel.latestSearchResult)
        XCTAssertEqual(viewModel.latestSearchResult?.city, city)
        XCTAssertTrue(completionCalled)
        XCTAssertFalse(viewModel.isLoadingState)
        XCTAssertNil(viewModel.errorMessageText)
    }
    
    /// Tests search with empty query shows error.
    func testSubmit_EmptyQuery_ShowsError() async {
        // Given
        viewModel.queryText = ""
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertFalse(mockSearchUseCase.executeCalled)
        XCTAssertEqual(viewModel.errorMessageText, "Please enter a valid location.")
    }
    
    /// Tests search with whitespace-only query shows error.
    func testSubmit_WhitespaceQuery_ShowsError() async {
        // Given
        viewModel.queryText = "   "
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertFalse(mockSearchUseCase.executeCalled)
        XCTAssertEqual(viewModel.errorMessageText, "Please enter a valid location.")
    }
    
    /// Tests search failure shows error message.
    func testSubmit_SearchFailure_ShowsError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "City not found"])
        mockSearchUseCase.searchError = expectedError
        viewModel.queryText = "InvalidCity"
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockSearchUseCase.executeCalled)
        XCTAssertEqual(viewModel.errorMessageText, "City not found")
        XCTAssertFalse(completionCalled)
        XCTAssertFalse(viewModel.isLoadingState)
    }
    
    /// Tests add failure shows error message.
    func testSubmit_AddFailure_ShowsError() async {
        // Given
        let city = CityFactory.makeCity()
        mockSearchUseCase.cityToReturn = city
        let expectedError = NSError(domain: "StorageError", code: 456, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        mockAddUseCase.addError = expectedError
        viewModel.queryText = "London"
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockSearchUseCase.executeCalled)
        XCTAssertTrue(mockAddUseCase.executeCalled)
        XCTAssertEqual(viewModel.errorMessageText, "Save failed")
        XCTAssertFalse(completionCalled)
    }
    
    // MARK: - Retry Tests
    
    /// Tests retry performs search again.
    func testRetry_PerformsSearch() async {
        // Given
        let city = CityFactory.makeCity()
        mockSearchUseCase.cityToReturn = city
        viewModel.queryText = "London"
        
        // When
        viewModel.retrySubject.send()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockSearchUseCase.executeCalled)
    }
    
    // MARK: - Publisher Tests
    
    /// Tests query publisher emits updates.
    func testQueryPublisher_EmitsUpdates() async {
        // Given
        let expectation = XCTestExpectation(description: "Query publisher emits")
        var receivedQueries: [String] = []
        
        viewModel.query
            .sink { query in
                receivedQueries.append(query)
                if !query.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.querySubject.send("London")
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertFalse(receivedQueries.isEmpty)
    }
    
    /// Tests isLoading publisher reflects loading state.
    func testIsLoadingPublisher_ReflectsState() async {
        // Given
        let expectation = XCTestExpectation(description: "IsLoading publisher emits")
        var loadingStates: [Bool] = []
        
        viewModel.isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let city = CityFactory.makeCity()
        mockSearchUseCase.cityToReturn = city
        viewModel.queryText = "London"
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(loadingStates.contains(true), "Should set loading to true")
        XCTAssertTrue(loadingStates.contains(false), "Should set loading to false")
    }
    
    /// Tests isQueryEmpty publisher reflects query state.
    func testIsQueryEmptyPublisher_ReflectsState() async {
        // Given
        let expectation = XCTestExpectation(description: "IsQueryEmpty publisher emits")
        var isEmptyStates: [Bool] = []
        
        viewModel.isQueryEmpty
            .sink { isEmpty in
                isEmptyStates.append(isEmpty)
                if isEmptyStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - set empty query
        viewModel.queryText = ""
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(isEmptyStates.contains(true), "Should emit true when query is empty")
    }
    
    /// Tests canSubmit publisher reflects query state.
    func testCanSubmitPublisher_ReflectsState() async {
        // Given
        let expectation = XCTestExpectation(description: "CanSubmit publisher emits")
        var canSubmitStates: [Bool] = []
        
        viewModel.canSubmit
            .sink { canSubmit in
                canSubmitStates.append(canSubmit)
                if canSubmitStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - set non-empty query
        viewModel.queryText = "London"
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(canSubmitStates.contains(true), "Should emit true when query is not empty")
    }
    
    /// Tests latestResult publisher emits search results.
    func testLatestResultPublisher_EmitsResults() async {
        // Given
        let expectation = XCTestExpectation(description: "LatestResult publisher emits")
        var receivedResults: [SearchResult?] = []
        
        viewModel.latestResult
            .sink { result in
                receivedResults.append(result)
                if result != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let city = CityFactory.makeCity()
        mockSearchUseCase.cityToReturn = city
        viewModel.queryText = "London"
        
        // When
        viewModel.submitSubject.send()
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(receivedResults.contains { $0 != nil }, "Should emit search result")
    }
}

