//
//  FetchWeatherIconUseCaseTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for FetchWeatherIconUseCase.
///
/// **Specification Interpretation:**
/// These tests verify that FetchWeatherIconUseCase correctly delegates to the repository
/// and returns the expected image data. All success and failure scenarios are covered.
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
final class FetchWeatherIconUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: FetchWeatherIconUseCase!
    private var mockRepository: MockWeatherIconRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockWeatherIconRepository()
        useCase = FetchWeatherIconUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository.reset()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful fetch of weather icon.
    func testExecute_Success_ReturnsImageData() async throws {
        // Given
        let expectedData = "test image data".data(using: .utf8)!
        mockRepository.imageDataToReturn = expectedData
        let iconCode = "01d"
        
        // When
        let result = try await useCase.execute(iconCode: iconCode)
        
        // Then
        XCTAssertEqual(result, expectedData)
        XCTAssertTrue(mockRepository.fetchCalled)
        XCTAssertEqual(mockRepository.fetchedIconCode, iconCode)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests fetch failure with repository error.
    func testExecute_Failure_ThrowsError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockRepository.fetchError = expectedError
        let iconCode = "01d"
        
        // When
        do {
            _ = try await useCase.execute(iconCode: iconCode)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 123)
            XCTAssertTrue(mockRepository.fetchCalled)
            XCTAssertEqual(mockRepository.fetchedIconCode, iconCode)
        }
    }
}

