//
//  SearchCityUseCaseTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for SearchCityUseCase.
///
/// **Specification Interpretation:**
/// These tests verify that SearchCityUseCase correctly delegates to the repository
/// and returns the expected city. All success and failure scenarios are covered.
///
/// **Thread Safety:**
/// - All async test methods properly await results
/// - Mock state is accessed through thread-safe properties
/// - No shared mutable state between tests (each test has isolated setup)
///
/// **Memory Management:**
/// - All properties are properly cleaned up in tearDown()
/// - No retain cycles (mocks don't hold strong references to test class)
/// - Mock state is reset between tests to prevent leaks
///
/// **Access Control:**
/// - Internal class: Used within test module
@MainActor
final class SearchCityUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: SearchCityUseCase!
    private var mockRepository: MockSearchRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockSearchRepository()
        useCase = SearchCityUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository.reset()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful search of a city.
    func testExecute_Success_ReturnsCity() async throws {
        // Given
        let expectedCity = CityFactory.makeCity(displayName: "London, GB")
        mockRepository.cityToReturn = expectedCity
        let query = "London"
        
        // When
        let result = try await useCase.execute(query: query)
        
        // Then
        XCTAssertEqual(result, expectedCity)
        XCTAssertTrue(mockRepository.searchCalled)
        XCTAssertEqual(mockRepository.searchedQuery, query)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests search failure with repository error.
    func testExecute_Failure_ThrowsError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockRepository.searchError = expectedError
        let query = "InvalidCity"
        
        // When
        do {
            _ = try await useCase.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 123)
            XCTAssertTrue(mockRepository.searchCalled)
            XCTAssertEqual(mockRepository.searchedQuery, query)
        }
    }
}

