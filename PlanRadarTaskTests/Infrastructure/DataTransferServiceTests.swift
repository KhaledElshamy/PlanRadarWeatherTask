//
//  DataTransferServiceTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Unit tests for DataTransferService.
///
/// **Specification Interpretation:**
/// These tests verify that DataTransferService correctly handles data transformation,
/// decoding, error resolution, and logging. All success and failure scenarios are covered.
///
/// **Thread Safety:**
/// - All async test methods properly await results
/// - Mock dependencies are thread-safe
/// - No shared mutable state between tests
///
/// **Memory Management:**
/// - All properties are properly cleaned up in tearDown()
/// - No retain cycles between mocks and service under test
/// - Mock state is isolated per test
///
/// **Access Control:**
/// - Internal class: Used within test module

@MainActor
final class DataTransferServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var dataTransferService: DefaultDataTransferService!
    private var mockNetworkService: MockNetworkService!
    private var mockErrorResolver: MockDataTransferErrorResolver!
    private var mockErrorLogger: MockDataTransferErrorLogger!
    private var mockDecoder: MockResponseDecoder!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockErrorResolver = MockDataTransferErrorResolver()
        mockErrorLogger = MockDataTransferErrorLogger()
        mockDecoder = MockResponseDecoder()
        
        dataTransferService = DefaultDataTransferService(
            with: mockNetworkService,
            errorResolver: mockErrorResolver,
            errorLogger: mockErrorLogger
        )
    }
    
    override func tearDown() {
        dataTransferService = nil
        mockNetworkService = nil
        mockErrorResolver = nil
        mockErrorLogger = nil
        mockDecoder = nil
        super.tearDown()
    }
    
    // MARK: - Success Scenarios
    
    /// Tests successful request with decodable response.
    func testRequest_Success_ReturnsDecodedObject() async throws {
        // Given
        let expectedResponse = MockResponse(id: 1, name: "Test")
        let responseData = try JSONEncoder().encode(expectedResponse)
        mockNetworkService.dataToReturn = responseData
        
        let endpoint = MockEndpoint(
            path: "/test",
            responseDecoder: JSONResponseDecoder()
        )
        
        // When
        let result: MockResponse = try await dataTransferService.request(with: endpoint)
        
        // Then
        XCTAssertEqual(result, expectedResponse)
        XCTAssertTrue(mockNetworkService.requestCalled)
        XCTAssertFalse(mockErrorLogger.logCalled)
    }
    
    /// Tests successful request with void response.
    func testRequest_VoidResponse_Success() async throws {
        // Given
        let responseData = "Success".data(using: .utf8)!
        mockNetworkService.dataToReturn = responseData
        
        struct VoidEndpoint: ResponseRequestable {
            typealias Response = Void
            let path = "/test"
            let isFullPath = false
            let method = HTTPMethodType.get
            let headerParameters: [String: String] = [:]
            let queryParametersEncodable: Encodable? = nil
            let queryParameters: [String: Any] = [:]
            let bodyParametersEncodable: Encodable? = nil
            let bodyParameters: [String: Any] = [:]
            let bodyEncoder: BodyEncoder = JSONBodyEncoder()
            let responseDecoder: ResponseDecoder = JSONResponseDecoder()
        }
        
        let endpoint = VoidEndpoint()
        
        // When
        try await dataTransferService.request(with: endpoint)
        
        // Then
        XCTAssertTrue(mockNetworkService.requestCalled)
        XCTAssertFalse(mockErrorLogger.logCalled)
    }
    
    // MARK: - Network Error Scenarios
    
    /// Tests request with network error that gets resolved.
    func testRequest_NetworkError_ResolvesAndThrows() async {
        // Given
        let networkError = NetworkError.notConnected
        mockNetworkService.errorToThrow = networkError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected DataTransferError to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .networkFailure(let resolvedError) = error {
                // resolvedError is already NetworkError, no need to cast
                XCTAssertEqual(resolvedError, networkError)
            } else {
                XCTFail("Expected .networkFailure case, got \(error)")
            }
            XCTAssertTrue(mockErrorResolver.resolveCalled)
            XCTAssertTrue(mockErrorLogger.logCalled)
            XCTAssertEqual(mockErrorLogger.logCallCount, 1)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    /// Tests request with network error that gets transformed.
    func testRequest_NetworkError_TransformsToResolvedError() async {
        // Given
        let networkError = NetworkError.notConnected
        let transformedError = NSError(domain: "CustomDomain", code: 999, userInfo: nil)
        mockNetworkService.errorToThrow = networkError
        mockErrorResolver.resolvedError = transformedError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected DataTransferError to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .resolvedNetworkFailure(let resolvedError) = error {
                let nsError = resolvedError as NSError
                XCTAssertEqual(nsError.domain, "CustomDomain")
                XCTAssertEqual(nsError.code, 999)
            } else {
                XCTFail("Expected .resolvedNetworkFailure case, got \(error)")
            }
            XCTAssertTrue(mockErrorResolver.resolveCalled)
            XCTAssertTrue(mockErrorLogger.logCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    /// Tests request with HTTP error status code.
    func testRequest_HTTPError_ResolvesAndThrows() async {
        // Given
        let httpError = NetworkError.error(statusCode: 404, data: nil)
        mockNetworkService.errorToThrow = httpError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected DataTransferError to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .networkFailure(let resolvedError) = error {
                // resolvedError is already NetworkError, no need to cast
                if case .error(let code, _) = resolvedError {
                    XCTAssertEqual(code, 404)
                } else {
                    XCTFail("Expected .error case with status code 404, got \(resolvedError)")
                }
            } else {
                XCTFail("Expected .networkFailure case, got \(error)")
            }
            XCTAssertTrue(mockErrorLogger.logCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    // MARK: - Decoding Error Scenarios
    
    /// Tests request with no response data.
    func testRequest_NoResponseData_ThrowsNoResponseError() async {
        // Given
        mockNetworkService.dataToReturn = nil
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected DataTransferError.noResponse to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .noResponse = error {
                // Success
            } else {
                XCTFail("Expected .noResponse case, got \(error)")
            }
            XCTAssertTrue(mockNetworkService.requestCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    /// Tests request with invalid JSON data.
    func testRequest_InvalidJSON_ThrowsParsingError() async {
        // Given
        let invalidData = "Invalid JSON".data(using: .utf8)!
        mockNetworkService.dataToReturn = invalidData
        
        let endpoint = MockEndpoint(
            path: "/test",
            responseDecoder: JSONResponseDecoder()
        )
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected DataTransferError.parsing to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .parsing(let decodingError) = error {
                XCTAssertTrue(decodingError is DecodingError)
            } else {
                XCTFail("Expected .parsing case, got \(error)")
            }
            XCTAssertTrue(mockNetworkService.requestCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    /// Tests request with decoding error from custom decoder.
    func testRequest_DecodingError_ThrowsParsingError() async {
        // Given
        let validData = "Valid Data".data(using: .utf8)!
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Test decoding error"
            )
        )
        mockNetworkService.dataToReturn = validData
        mockDecoder.decodingError = decodingError
        
        let endpoint = MockEndpoint(
            path: "/test",
            responseDecoder: mockDecoder
        )
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected DataTransferError.parsing to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .parsing(let parsedError) = error {
                XCTAssertTrue(parsedError is DecodingError)
            } else {
                XCTFail("Expected .parsing case, got \(error)")
            }
            XCTAssertTrue(mockNetworkService.requestCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    // MARK: - Generic Error Scenarios
    
    /// Tests request with generic error (not NetworkError).
    func testRequest_GenericError_ThrowsAndLogs() async {
        // Given
        let genericError = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        mockNetworkService.errorToThrow = genericError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(mockErrorLogger.logCalled)
            XCTAssertNotNil(mockErrorLogger.loggedError)
        }
    }
    
    // MARK: - Error Logger Tests
    
    /// Tests that network errors are logged.
    func testRequest_NetworkError_LogsError() async {
        // Given
        let networkError = NetworkError.notConnected
        mockNetworkService.errorToThrow = networkError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try? await dataTransferService.request(with: endpoint) as MockResponse
        
        // Then
        XCTAssertTrue(mockErrorLogger.logCalled)
        XCTAssertNotNil(mockErrorLogger.loggedError)
    }
    
    /// Tests that decoding errors are logged.
    func testRequest_DecodingError_LogsError() async {
        // Given
        let invalidData = "Invalid".data(using: .utf8)!
        mockNetworkService.dataToReturn = invalidData
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try? await dataTransferService.request(with: endpoint) as MockResponse
        
        // Then
        XCTAssertTrue(mockErrorLogger.logCalled)
    }
    
    // MARK: - Error Resolver Tests
    
    /// Tests that network errors are passed to resolver.
    func testRequest_NetworkError_PassesToResolver() async {
        // Given
        let networkError = NetworkError.cancelled
        mockNetworkService.errorToThrow = networkError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try? await dataTransferService.request(with: endpoint) as MockResponse
        
        // Then
        XCTAssertTrue(mockErrorResolver.resolveCalled)
        if let resolvedError = mockErrorResolver.resolvedNetworkError {
            XCTAssertEqual(resolvedError, networkError)
        } else {
            XCTFail("Expected resolvedNetworkError to be set")
        }
    }
}

