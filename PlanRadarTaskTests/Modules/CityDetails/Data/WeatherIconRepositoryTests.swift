//
//  WeatherIconRepositoryTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for WeatherIconRepositoryImpl.
///
/// **Specification Interpretation:**
/// These tests verify that WeatherIconRepositoryImpl correctly handles network requests,
/// validates icon codes, and handles errors (especially 404 for icon not found).
/// All success and failure scenarios are covered.
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
final class WeatherIconRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: WeatherIconRepositoryImpl!
    private var mockDataTransferService: MockDataTransferService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockDataTransferService = MockDataTransferService()
        repository = WeatherIconRepositoryImpl(network: mockDataTransferService)
    }
    
    override func tearDown() {
        mockDataTransferService.reset()
        repository = nil
        mockDataTransferService = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful icon fetch with valid icon code.
    func testFetchWeatherIcon_Success_ReturnsImageData() async throws {
        // Given
        let iconCode = "01d"
        let expectedData = "test image data".data(using: .utf8)!
        mockDataTransferService.responseToReturn = expectedData
        
        // When
        let result = try await repository.fetchWeatherIcon(iconCode: iconCode)
        
        // Then
        XCTAssertEqual(result, expectedData)
        XCTAssertTrue(mockDataTransferService.requestCalled)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests empty icon code throws invalidIconCode error.
    func testFetchWeatherIcon_EmptyIconCode_ThrowsInvalidIconCodeError() async {
        // Given
        let iconCode = ""
        
        // When
        do {
            _ = try await repository.fetchWeatherIcon(iconCode: iconCode)
            XCTFail("Expected WeatherIconRepositoryError.invalidIconCode to be thrown")
        } catch let error as WeatherIconRepositoryImpl.WeatherIconRepositoryError {
            // Then
            if case .invalidIconCode(let code) = error {
                XCTAssertEqual(code, iconCode)
            } else {
                XCTFail("Expected .invalidIconCode case, got \(error)")
            }
            XCTAssertFalse(mockDataTransferService.requestCalled)
        } catch {
            XCTFail("Expected WeatherIconRepositoryError, got \(error)")
        }
    }
    
    /// Tests icon not found (404 error) is converted to iconNotFound error.
    func testFetchWeatherIcon_IconNotFound_ThrowsIconNotFoundError() async {
        // Given
        let iconCode = "99x"
        let networkError = NetworkError.error(statusCode: 404, data: nil)
        mockDataTransferService.errorToThrow = networkError
        
        // When
        do {
            _ = try await repository.fetchWeatherIcon(iconCode: iconCode)
            XCTFail("Expected WeatherIconRepositoryError.iconNotFound to be thrown")
        } catch let error as WeatherIconRepositoryImpl.WeatherIconRepositoryError {
            // Then
            if case .iconNotFound(let code) = error {
                XCTAssertEqual(code, iconCode)
            } else {
                XCTFail("Expected .iconNotFound case, got \(error)")
            }
            XCTAssertTrue(mockDataTransferService.requestCalled)
        } catch {
            XCTFail("Expected WeatherIconRepositoryError, got \(error)")
        }
    }
    
    /// Tests other network errors are converted to networkError.
    func testFetchWeatherIcon_NetworkError_ThrowsNetworkError() async {
        // Given
        let iconCode = "01d"
        let networkError = NetworkError.notConnected
        mockDataTransferService.errorToThrow = networkError
        
        // When
        do {
            _ = try await repository.fetchWeatherIcon(iconCode: iconCode)
            XCTFail("Expected WeatherIconRepositoryError.networkError to be thrown")
        } catch let error as WeatherIconRepositoryImpl.WeatherIconRepositoryError {
            // Then
            if case .networkError(let underlyingError) = error {
                XCTAssertTrue(underlyingError is NetworkError)
            } else {
                XCTFail("Expected .networkError case, got \(error)")
            }
            XCTAssertTrue(mockDataTransferService.requestCalled)
        } catch {
            XCTFail("Expected WeatherIconRepositoryError, got \(error)")
        }
    }
    
    /// Tests generic errors are converted to networkError.
    func testFetchWeatherIcon_GenericError_ThrowsNetworkError() async {
        // Given
        let iconCode = "01d"
        let genericError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockDataTransferService.errorToThrow = genericError
        
        // When
        do {
            _ = try await repository.fetchWeatherIcon(iconCode: iconCode)
            XCTFail("Expected WeatherIconRepositoryError.networkError to be thrown")
        } catch let error as WeatherIconRepositoryImpl.WeatherIconRepositoryError {
            // Then
            if case .networkError = error {
                // Success
            } else {
                XCTFail("Expected .networkError case, got \(error)")
            }
            XCTAssertTrue(mockDataTransferService.requestCalled)
        } catch {
            XCTFail("Expected WeatherIconRepositoryError, got \(error)")
        }
    }
}

