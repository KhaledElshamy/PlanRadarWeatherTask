//
//  FetchCitiesUseCaseTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for FetchCitiesUseCase.
///
/// **Specification Interpretation:**
/// These tests verify that FetchCitiesUseCase correctly delegates to the repository
/// and returns the expected cities. All success and failure scenarios are covered.
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
final class FetchCitiesUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: FetchCitiesUseCase!
    private var mockRepository: MockCitiesRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockCitiesRepository()
        useCase = FetchCitiesUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository.reset()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful fetch of cities.
    func testExecute_Success_ReturnsCities() async throws {
        // Given
        let expectedCities = CityFactory.makeCities(count: 3)
        mockRepository.citiesToReturn = expectedCities
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result, expectedCities)
        XCTAssertTrue(mockRepository.fetchCalled)
    }
    
    /// Tests successful fetch with empty cities list.
    func testExecute_Success_ReturnsEmptyList() async throws {
        // Given
        mockRepository.citiesToReturn = []
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockRepository.fetchCalled)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests fetch failure with repository error.
    func testExecute_Failure_ThrowsError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockRepository.fetchError = expectedError
        
        // When
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 123)
            XCTAssertTrue(mockRepository.fetchCalled)
        }
    }
}

