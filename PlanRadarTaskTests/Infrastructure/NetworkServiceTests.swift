//
//  NetworkServiceTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for NetworkService.
///
/// **Specification Interpretation:**
/// These tests verify that NetworkService correctly handles network requests,
/// error resolution, logging, and URL generation. All success and failure
/// scenarios are covered.
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
///

@MainActor
final class NetworkServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var networkService: DefaultNetworkService!
    private var mockConfig: MockNetworkConfig!
    private var mockLogger: MockNetworkErrorLogger!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockConfig = MockNetworkConfig()
        mockLogger = MockNetworkErrorLogger()
        
        // Use real ObjCNetworkPerformer with URLProtocol interception
        // Configure URLProtocol to intercept network calls
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let performer = ObjCNetworkPerformer(session: session)
        
        networkService = DefaultNetworkService(
            config: mockConfig,
            performer: performer,
            logger: mockLogger
        )
        
        // Reset URLProtocol state
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        MockURLProtocol.reset()
        networkService = nil
        mockConfig = nil
        mockLogger = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful network request with data response.
    func testRequest_Success_ReturnsData() async throws {
        // Given
        let expectedData = "Test Response".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return mock data
        MockURLProtocol.requestHandler = { _ in
            return (expectedData, mockResponse)
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        let result = try await networkService.request(endpoint: endpoint)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedData)
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertTrue(mockLogger.logResponseCalled)
        XCTAssertFalse(mockLogger.logErrorCalled)
    }
    
    /// Tests successful network request with nil data response.
    func testRequest_Success_ReturnsNilData() async throws {
        // Given
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return nil data
        // Note: URLSession may convert nil to empty Data, so we accept both
        MockURLProtocol.requestHandler = { _ in
            return (nil, mockResponse)
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        let result = try await networkService.request(endpoint: endpoint)
        
        // Then
        // URLSession may return empty Data instead of nil for 204 responses
        // Both are acceptable for a "no content" response
        XCTAssertTrue(result == nil || result?.isEmpty == true, "Expected nil or empty Data, got \(String(describing: result))")
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertTrue(mockLogger.logResponseCalled)
    }
    
    // MARK: - Error Scenarios
    
    /// Tests network request with HTTP error status code.
    func testRequest_HTTPError_ThrowsNetworkError() async {
        // Given
        let statusCode = 404
        let errorData = "Not Found".data(using: .utf8)
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return error response
        MockURLProtocol.requestHandler = { _ in
            let error = NSError(
                domain: ObjCNetworkErrorDomain,
                code: statusCode,
                userInfo: [
                    ObjCNetworkStatusCodeKey: statusCode,
                    ObjCNetworkResponseDataKey: errorData as Any
                ]
            )
            throw error
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            _ = try await networkService.request(endpoint: endpoint)
            XCTFail("Expected NetworkError.error to be thrown")
        } catch let networkError as NetworkError {
            // Then
            if case .error(let code, let data) = networkError {
                XCTAssertEqual(code, statusCode)
                XCTAssertEqual(data, errorData)
            } else {
                XCTFail("Expected .error case, got \(networkError)")
            }
            XCTAssertTrue(mockLogger.logRequestCalled)
            XCTAssertTrue(mockLogger.logErrorCalled)
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    /// Tests network request with no internet connection error.
    func testRequest_NoConnection_ThrowsNotConnectedError() async {
        // Given
        let urlError = URLError(.notConnectedToInternet)
        
        // Configure URLProtocol to throw connection error
        MockURLProtocol.requestHandler = { _ in
            throw urlError
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            _ = try await networkService.request(endpoint: endpoint)
            XCTFail("Expected NetworkError.notConnected to be thrown")
        } catch let networkError as NetworkError {
            // Then
            if case .notConnected = networkError {
                // Success
            } else {
                XCTFail("Expected .notConnected case, got \(networkError)")
            }
            XCTAssertTrue(mockLogger.logErrorCalled)
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    /// Tests network request with cancelled error.
    func testRequest_Cancelled_ThrowsCancelledError() async {
        // Given
        let urlError = URLError(.cancelled)
        
        // Configure URLProtocol to throw cancelled error
        MockURLProtocol.requestHandler = { _ in
            throw urlError
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            _ = try await networkService.request(endpoint: endpoint)
            XCTFail("Expected NetworkError.cancelled to be thrown")
        } catch let networkError as NetworkError {
            // Then
            if case .cancelled = networkError {
                // Success
            } else {
                XCTFail("Expected .cancelled case, got \(networkError)")
            }
            XCTAssertTrue(mockLogger.logErrorCalled)
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    /// Tests network request with generic error.
    func testRequest_GenericError_ThrowsGenericError() async {
        // Given
        let genericError = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        
        // Configure URLProtocol to throw generic error
        MockURLProtocol.requestHandler = { _ in
            throw genericError
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            _ = try await networkService.request(endpoint: endpoint)
            XCTFail("Expected NetworkError.generic to be thrown")
        } catch let networkError as NetworkError {
            // Then
            if case .generic(let error) = networkError {
                XCTAssertEqual((error as NSError).domain, "TestDomain")
                XCTAssertEqual((error as NSError).code, 123)
            } else {
                XCTFail("Expected .generic case, got \(networkError)")
            }
            XCTAssertTrue(mockLogger.logErrorCalled)
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    /// Tests network request with invalid URL generation.
    func testRequest_InvalidURL_ThrowsURLGenerationError() async {
        // Given
        // Use a custom endpoint that throws RequestGenerationError.components
        // This is more reliable than trying to create an invalid URL string,
        // as URLComponents is very lenient and may not fail with malformed paths
        let invalidEndpoint = InvalidMockEndpoint()
        
        // When
        do {
            _ = try await networkService.request(endpoint: invalidEndpoint)
            XCTFail("Expected NetworkError.urlGeneration to be thrown")
        } catch let networkError as NetworkError {
            // Then
            if case .urlGeneration = networkError {
                // Success - URL generation failed as expected
            } else {
                XCTFail("Expected .urlGeneration case, got \(networkError)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    // MARK: - Logging Tests
    
    /// Tests that request is logged before execution.
    func testRequest_LogsRequest() async throws {
        // Given
        let expectedData = "Test".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return success
        MockURLProtocol.requestHandler = { _ in
            return (expectedData, mockResponse)
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try await networkService.request(endpoint: endpoint)
        
        // Then
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertNotNil(mockLogger.loggedRequest)
    }
    
    /// Tests that response is logged after successful execution.
    func testRequest_LogsResponse() async throws {
        // Given
        let expectedData = "Test".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return success
        MockURLProtocol.requestHandler = { _ in
            return (expectedData, mockResponse)
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try await networkService.request(endpoint: endpoint)
        
        // Then
        XCTAssertTrue(mockLogger.logResponseCalled)
        XCTAssertEqual(mockLogger.loggedResponseData, expectedData)
        XCTAssertNotNil(mockLogger.loggedResponse)
    }
    
    /// Tests that errors are logged when they occur.
    func testRequest_LogsError() async {
        // Given
        let error = URLError(.notConnectedToInternet)
        
        // Configure URLProtocol to throw error
        MockURLProtocol.requestHandler = { _ in
            throw error
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try? await networkService.request(endpoint: endpoint)
        
        // Then
        XCTAssertTrue(mockLogger.logErrorCalled)
        XCTAssertNotNil(mockLogger.loggedError)
    }
}

