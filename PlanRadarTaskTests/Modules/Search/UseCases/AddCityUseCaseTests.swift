//
//  AddCityUseCaseTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for AddCityUseCase.
///
/// **Specification Interpretation:**
/// These tests verify that AddCityUseCase correctly delegates to the storage
/// layer and handles save operations. All success and failure scenarios are covered.
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
final class AddCityUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: AddCityUseCase!
    private var mockStorage: MockCitiesStorage!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockStorage = MockCitiesStorage()
        useCase = AddCityUseCase(storage: mockStorage)
    }
    
    override func tearDown() {
        mockStorage.reset()
        useCase = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful addition of a city.
    func testExecute_Success_SavesCity() async throws {
        // Given
        let cityToAdd = CityFactory.makeCity()
        
        // When
        try await useCase.execute(city: cityToAdd)
        
        // Then
        XCTAssertTrue(mockStorage.saveCalled)
        XCTAssertEqual(mockStorage.savedCity, cityToAdd)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests addition failure with storage error.
    func testExecute_Failure_ThrowsError() async {
        // Given
        let cityToAdd = CityFactory.makeCity()
        let expectedError = NSError(domain: "StorageError", code: 456, userInfo: nil)
        mockStorage.saveError = expectedError
        
        // When
        do {
            try await useCase.execute(city: cityToAdd)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "StorageError")
            XCTAssertEqual((error as NSError).code, 456)
            XCTAssertTrue(mockStorage.saveCalled)
            XCTAssertEqual(mockStorage.savedCity, cityToAdd)
        }
    }
}

