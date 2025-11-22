//
//  DeleteCityUseCaseTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for DeleteCityUseCase.
///
/// **Specification Interpretation:**
/// These tests verify that DeleteCityUseCase correctly delegates to the repository
/// and handles deletion operations. All success and failure scenarios are covered.
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
final class DeleteCityUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: DeleteCityUseCase!
    private var mockRepository: MockCitiesRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockCitiesRepository()
        useCase = DeleteCityUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository.reset()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful deletion of a city.
    func testExecute_Success_DeletesCity() async throws {
        // Given
        let cityToDelete = CityFactory.makeCity()
        
        // When
        try await useCase.execute(city: cityToDelete)
        
        // Then
        XCTAssertTrue(mockRepository.deleteCalled)
        XCTAssertEqual(mockRepository.deletedCity, cityToDelete)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests deletion failure with repository error.
    func testExecute_Failure_ThrowsError() async {
        // Given
        let cityToDelete = CityFactory.makeCity()
        let expectedError = NSError(domain: "TestError", code: 456, userInfo: nil)
        mockRepository.deleteError = expectedError
        
        // When
        do {
            try await useCase.execute(city: cityToDelete)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 456)
            XCTAssertTrue(mockRepository.deleteCalled)
            XCTAssertEqual(mockRepository.deletedCity, cityToDelete)
        }
    }
}

