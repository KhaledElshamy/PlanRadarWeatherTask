//
//  CitiesRepositoryTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for CitiesRepositoryImpl.
///
/// **Specification Interpretation:**
/// These tests verify that CitiesRepositoryImpl correctly delegates to the storage
/// layer and handles all repository operations. All success and failure scenarios are covered.
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
final class CitiesRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: CitiesRepositoryImpl!
    private var mockStorage: MockCitiesStorage!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockStorage = MockCitiesStorage()
        repository = CitiesRepositoryImpl(storage: mockStorage)
    }
    
    override func tearDown() {
        mockStorage.reset()
        repository = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Cities Tests
    
    /// Tests successful fetch of cities from storage.
    func testFetchSavedCities_Success_ReturnsCities() async throws {
        // Given
        let expectedCities = CityFactory.makeCities(count: 3)
        mockStorage.citiesToReturn = expectedCities
        
        // When
        let result = try await repository.fetchSavedCities()
        
        // Then
        XCTAssertEqual(result, expectedCities)
        XCTAssertTrue(mockStorage.fetchCalled)
    }
    
    /// Tests successful fetch with empty cities list.
    func testFetchSavedCities_Success_ReturnsEmptyList() async throws {
        // Given
        mockStorage.citiesToReturn = []
        
        // When
        let result = try await repository.fetchSavedCities()
        
        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockStorage.fetchCalled)
    }
    
    /// Tests fetch failure with storage error.
    func testFetchSavedCities_Failure_ThrowsError() async {
        // Given
        let expectedError = NSError(domain: "StorageError", code: 789, userInfo: nil)
        mockStorage.fetchError = expectedError
        
        // When
        do {
            _ = try await repository.fetchSavedCities()
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "StorageError")
            XCTAssertEqual((error as NSError).code, 789)
            XCTAssertTrue(mockStorage.fetchCalled)
        }
    }
    
    // MARK: - Delete City Tests
    
    /// Tests successful deletion of a city.
    func testDelete_Success_DeletesCity() async throws {
        // Given
        let cityToDelete = CityFactory.makeCity()
        
        // When
        try await repository.delete(cityToDelete)
        
        // Then
        XCTAssertTrue(mockStorage.deleteCalled)
        XCTAssertEqual(mockStorage.deletedCity, cityToDelete)
    }
    
    /// Tests deletion failure with storage error.
    func testDelete_Failure_ThrowsError() async {
        // Given
        let cityToDelete = CityFactory.makeCity()
        let expectedError = NSError(domain: "StorageError", code: 999, userInfo: nil)
        mockStorage.deleteError = expectedError
        
        // When
        do {
            try await repository.delete(cityToDelete)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "StorageError")
            XCTAssertEqual((error as NSError).code, 999)
            XCTAssertTrue(mockStorage.deleteCalled)
            XCTAssertEqual(mockStorage.deletedCity, cityToDelete)
        }
    }
}

