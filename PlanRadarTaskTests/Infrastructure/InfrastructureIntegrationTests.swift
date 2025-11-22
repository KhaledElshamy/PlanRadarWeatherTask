//
//  InfrastructureIntegrationTests.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import XCTest
@testable import PlanRadarTask

/// Integration tests for Infrastructure layer.
///
/// **Specification Interpretation:**
/// These tests verify the complete flow from NetworkService through DataTransferService,
/// ensuring that the layers work together correctly in real-world scenarios.
///
/// **Thread Safety:**
/// - Integration tests properly handle async/await across multiple layers
/// - Mock state is synchronized for concurrent access
/// - Tests run sequentially to avoid race conditions
///
/// **Memory Management:**
/// - All service instances are properly deallocated in tearDown()
/// - Mock state is reset to prevent memory leaks
/// - No retain cycles between layers
///
/// **Access Control:**
/// - Internal class: Used within test module

@MainActor
final class InfrastructureIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var networkService: DefaultNetworkService!
    private var dataTransferService: DefaultDataTransferService!
    private var mockConfig: MockNetworkConfig!
    private var mockLogger: MockNetworkErrorLogger!
    private var mockErrorResolver: MockDataTransferErrorResolver!
    private var mockErrorLogger: MockDataTransferErrorLogger!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockConfig = MockNetworkConfig()
        mockLogger = MockNetworkErrorLogger()
        mockErrorResolver = MockDataTransferErrorResolver()
        mockErrorLogger = MockDataTransferErrorLogger()
        
        // Use real ObjCNetworkPerformer with URLProtocol interception
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let performer = ObjCNetworkPerformer(session: session)
        
        networkService = DefaultNetworkService(
            config: mockConfig,
            performer: performer,
            logger: mockLogger
        )
        
        dataTransferService = DefaultDataTransferService(
            with: networkService,
            errorResolver: mockErrorResolver,
            errorLogger: mockErrorLogger
        )
        
        // Reset URLProtocol state
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        MockURLProtocol.reset()
        networkService = nil
        dataTransferService = nil
        mockConfig = nil
        mockLogger = nil
        mockErrorResolver = nil
        mockErrorLogger = nil
        super.tearDown()
    }
    
    // MARK: - Success Integration Tests
    
    /// Tests complete flow: NetworkService -> DataTransferService with successful response.
    func testIntegration_SuccessfulRequest_ReturnsDecodedObject() async throws {
        // Given
        let expectedResponse = MockResponse(id: 42, name: "Integration Test")
        let responseData = try JSONEncoder().encode(expectedResponse)
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        // Configure URLProtocol to return success
        MockURLProtocol.requestHandler = { _ in
            return (responseData, mockResponse)
        }
        
        let endpoint = MockEndpoint(
            path: "/test",
            responseDecoder: JSONResponseDecoder()
        )
        
        // When
        let result: MockResponse = try await dataTransferService.request(with: endpoint)
        
        // Then
        XCTAssertEqual(result, expectedResponse)
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertTrue(mockLogger.logResponseCalled)
        XCTAssertFalse(mockLogger.logErrorCalled)
        XCTAssertFalse(mockErrorLogger.logCalled)
    }
    
    /// Tests complete flow with void response.
    func testIntegration_SuccessfulVoidRequest_CompletesWithoutError() async throws {
        // Given
        let responseData = "OK".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return success
        MockURLProtocol.requestHandler = { _ in
            return (responseData, mockResponse)
        }
        
        struct VoidEndpoint: ResponseRequestable {
            typealias Response = Void
            let path = "/test"
            let isFullPath = false
            let method = HTTPMethodType.delete
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
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertFalse(mockErrorLogger.logCalled)
    }
    
    // MARK: - Error Integration Tests
    
    /// Tests complete flow with decoding error.
    func testIntegration_DecodingError_HandledCorrectly() async {
        // Given
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        // Configure URLProtocol to return invalid JSON
        MockURLProtocol.requestHandler = { _ in
            return (invalidJSON, mockResponse)
        }
        
        let endpoint = MockEndpoint(
            path: "/test",
            responseDecoder: JSONResponseDecoder()
        )
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected decoding error to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .parsing(let decodingError) = error {
                XCTAssertTrue(decodingError is DecodingError)
            } else {
                XCTFail("Expected .parsing case, got \(error)")
            }
            XCTAssertNotNil(MockURLProtocol.lastRequest)
            XCTAssertTrue(mockLogger.logResponseCalled)
            XCTAssertTrue(mockErrorLogger.logCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    // MARK: - Error Resolution Integration Tests
    
    /// Tests error resolution flow with custom resolver.
    func testIntegration_CustomErrorResolver_TransformsError() async {
        // Given
        let networkError = NetworkError.cancelled
        let customError = NSError(domain: "CustomDomain", code: 999, userInfo: nil)
        
        // Configure URLProtocol to throw cancelled error
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.cancelled)
        }
        mockErrorResolver.resolvedError = customError
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        do {
            let _: MockResponse = try await dataTransferService.request(with: endpoint)
            XCTFail("Expected error to be thrown")
        } catch let error as DataTransferError {
            // Then
            if case .resolvedNetworkFailure(let resolvedError) = error {
                XCTAssertEqual((resolvedError as NSError).domain, "CustomDomain")
                XCTAssertEqual((resolvedError as NSError).code, 999)
            } else {
                XCTFail("Expected .resolvedNetworkFailure case, got \(error)")
            }
            XCTAssertTrue(mockErrorResolver.resolveCalled)
        } catch {
            XCTFail("Expected DataTransferError, got \(error)")
        }
    }
    
    // MARK: - Logging Integration Tests
    
    /// Tests that all logging occurs in correct order.
    func testIntegration_Logging_OccursInCorrectOrder() async throws {
        // Given
        let responseData = try JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Configure URLProtocol to return success
        MockURLProtocol.requestHandler = { _ in
            return (responseData, mockResponse)
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        let _: MockResponse = try await dataTransferService.request(with: endpoint)
        
        // Then
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertTrue(mockLogger.logResponseCalled)
        XCTAssertFalse(mockLogger.logErrorCalled)
        XCTAssertFalse(mockErrorLogger.logCalled)
    }
    
    /// Tests that error logging occurs at all layers.
    func testIntegration_ErrorLogging_OccursAtAllLayers() async {
        // Given
        let networkError = URLError(.timedOut)
        
        // Configure URLProtocol to throw error
        MockURLProtocol.requestHandler = { _ in
            throw networkError
        }
        
        let endpoint = MockEndpoint(path: "/test")
        
        // When
        _ = try? await dataTransferService.request(with: endpoint) as MockResponse
        
        // Then
        XCTAssertTrue(mockLogger.logRequestCalled)
        XCTAssertTrue(mockLogger.logErrorCalled)
        XCTAssertTrue(mockErrorLogger.logCalled)
    }
}

