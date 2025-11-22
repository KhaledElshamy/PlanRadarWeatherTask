//
//  MockEndpoint.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock endpoint for testing.
///
/// **Access Control:**
/// - Internal struct: Used within test module
struct MockEndpoint: ResponseRequestable {
    typealias Response = MockResponse
    
    let path: String
    let isFullPath: Bool
    let method: HTTPMethodType
    let headerParameters: [String: String]
    let queryParametersEncodable: Encodable?
    let queryParameters: [String: Any]
    let bodyParametersEncodable: Encodable?
    let bodyParameters: [String: Any]
    let bodyEncoder: BodyEncoder
    let responseDecoder: ResponseDecoder
    
    /// Initializes a mock endpoint.
    ///
    /// **Thread Safety:** This initializer is nonisolated to allow creation
    /// from any actor context, ensuring thread-safe test execution.
    ///
    /// - Parameters:
    ///   - path: Endpoint path (default: "/test")
    ///   - method: HTTP method (default: .get)
    ///   - responseDecoder: Response decoder (default: JSONResponseDecoder)
    nonisolated init(
        path: String = "/test",
        method: HTTPMethodType = .get,
        responseDecoder: ResponseDecoder = JSONResponseDecoder()
    ) {
        self.path = path
        self.isFullPath = false
        self.method = method
        self.headerParameters = [:]
        self.queryParametersEncodable = nil
        self.queryParameters = [:]
        self.bodyParametersEncodable = nil
        self.bodyParameters = [:]
        self.bodyEncoder = JSONBodyEncoder()
        self.responseDecoder = responseDecoder
    }
}

/// Mock endpoint that throws URL generation error for testing.
///
/// **Access Control:**
/// - Internal struct: Used within test module
struct InvalidMockEndpoint: ResponseRequestable {
    typealias Response = MockResponse
    
    let path: String
    let isFullPath: Bool
    let method: HTTPMethodType
    let headerParameters: [String: String]
    let queryParametersEncodable: Encodable?
    let queryParameters: [String: Any]
    let bodyParametersEncodable: Encodable?
    let bodyParameters: [String: Any]
    let bodyEncoder: BodyEncoder
    let responseDecoder: ResponseDecoder
    
    /// Initializes an invalid mock endpoint that throws URL generation error.
    nonisolated init() {
        self.path = "/test"
        self.isFullPath = false
        self.method = .get
        self.headerParameters = [:]
        self.queryParametersEncodable = nil
        self.queryParameters = [:]
        self.bodyParametersEncodable = nil
        self.bodyParameters = [:]
        self.bodyEncoder = JSONBodyEncoder()
        self.responseDecoder = JSONResponseDecoder()
    }
    
    /// Override urlRequest to throw RequestGenerationError for testing.
    func urlRequest(with networkConfig: NetworkConfigurable) throws -> URLRequest {
        throw RequestGenerationError.components
    }
}

/// Mock response model for testing.
///
/// **Access Control:**
/// - Internal struct: Used within test module
/// **Thread Safety:** Value type, inherently thread-safe
struct MockResponse: Codable, Equatable {
    let id: Int
    let name: String
    
    /// Initializes a mock response.
    ///
    /// **Thread Safety:** Nonisolated initializer for thread-safe creation.
    ///
    /// - Parameters:
    ///   - id: Response ID (default: 1)
    ///   - name: Response name (default: "Test")
    nonisolated init(id: Int = 1, name: String = "Test") {
        self.id = id
        self.name = name
    }
}

