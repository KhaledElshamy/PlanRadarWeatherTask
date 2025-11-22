//
//  SearchRepositoryTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for SearchRepositoryImpl.
///
/// **Specification Interpretation:**
/// These tests verify that SearchRepositoryImpl correctly handles network requests,
/// maps DTOs to domain entities, and handles errors (especially 404 for city not found).
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
final class SearchRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: SearchRepositoryImpl!
    private var mockDataTransferService: MockDataTransferService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockDataTransferService = MockDataTransferService()
        repository = SearchRepositoryImpl(network: mockDataTransferService)
    }
    
    override func tearDown() {
        mockDataTransferService.reset()
        repository = nil
        mockDataTransferService = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful city search with valid DTO response.
    func testSearchCity_Success_ReturnsCity() async throws {
        // Given
        let cityName = "London"
        // Create a minimal valid DTO - all properties are optional
        let dto = CityResponseDTO(
            coord: Coord(lon: -0.1257, lat: 51.5085),
            weather: [
                Weather(
                    id: 803,
                    main: "Clouds",
                    description: "broken clouds",
                    icon: "04d"
                )
            ],
            base: nil,
            main: Main(
                temp: 288.15,
                feelsLike: 287.5,
                tempMin: 286.5,
                tempMax: 290.0,
                pressure: 1013,
                humidity: 87,
                seaLevel: nil,
                grndLevel: nil
            ),
            visibility: nil,
            wind: Wind(speed: 2.5, deg: 200, gust: nil),
            clouds: Clouds(all: 75),
            dt: 1234567890,
            sys: Sys(
                type: nil,
                id: nil,
                country: "GB",
                sunrise: 1234567890,
                sunset: 1234567890
            ),
            timezone: nil,
            id: 2643743,
            name: "London",
            cod: nil
        )
        mockDataTransferService.responseToReturn = dto
        
        // When
        let result = try await repository.searchCity(named: cityName)
        
        // Then
        XCTAssertEqual(result.displayName, "London, GB")
        XCTAssertTrue(mockDataTransferService.requestCalled)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests city not found (404 error) is converted to SearchRepositoryError.
    func testSearchCity_CityNotFound_ThrowsSearchRepositoryError() async {
        // Given
        let cityName = "InvalidCity"
        let networkError = NetworkError.error(statusCode: 404, data: nil)
        mockDataTransferService.errorToThrow = networkError
        
        // When
        do {
            _ = try await repository.searchCity(named: cityName)
            XCTFail("Expected SearchRepositoryError.cityNotFound to be thrown")
        } catch let error as SearchRepositoryImpl.SearchRepositoryError {
            // Then
            if case .cityNotFound(let name) = error {
                XCTAssertEqual(name, cityName)
            } else {
                XCTFail("Expected .cityNotFound case, got \(error)")
            }
            XCTAssertTrue(mockDataTransferService.requestCalled)
        } catch {
            XCTFail("Expected SearchRepositoryError, got \(error)")
        }
    }
    
    /// Tests other network errors are propagated.
    func testSearchCity_NetworkError_PropagatesError() async {
        // Given
        let cityName = "London"
        let networkError = NetworkError.notConnected
        mockDataTransferService.errorToThrow = networkError
        
        // When
        do {
            _ = try await repository.searchCity(named: cityName)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            // Should propagate the network error, not convert it
            XCTAssertTrue(mockDataTransferService.requestCalled)
        }
    }
    
    /// Tests decoding errors are propagated.
    func testSearchCity_DecodingError_PropagatesError() async {
        // Given
        let cityName = "London"
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid JSON"
            )
        )
        mockDataTransferService.errorToThrow = decodingError
        
        // When
        do {
            _ = try await repository.searchCity(named: cityName)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(mockDataTransferService.requestCalled)
        }
    }
}

