//
//  Endpoint.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// HTTP method types for API requests.
///
/// **Access Control:**
/// - Internal enum: Used within the infrastructure module
enum HTTPMethodType: String {
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}

/// Generic endpoint class that configures API requests.
///
/// **Specification Interpretation:**
/// This class encapsulates all aspects of an API endpoint: path, method, headers,
/// query parameters, body parameters, and response decoding. It provides a flexible
/// and type-safe way to define API endpoints.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
/// - Generic type R: The response type this endpoint returns
class Endpoint<R>: ResponseRequestable {
    
    typealias Response = R
    
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
    
    init(path: String,
         isFullPath: Bool = false,
         method: HTTPMethodType,
         headerParameters: [String: String] = [:],
         queryParametersEncodable: Encodable? = nil,
         queryParameters: [String: Any] = [:],
         bodyParametersEncodable: Encodable? = nil,
         bodyParameters: [String: Any] = [:],
         bodyEncoder: BodyEncoder = JSONBodyEncoder(),
         responseDecoder: ResponseDecoder = JSONResponseDecoder()) {
        self.path = path
        self.isFullPath = isFullPath
        self.method = method
        self.headerParameters = headerParameters
        self.queryParametersEncodable = queryParametersEncodable
        self.queryParameters = queryParameters
        self.bodyParametersEncodable = bodyParametersEncodable
        self.bodyParameters = bodyParameters
        self.bodyEncoder = bodyEncoder
        self.responseDecoder = responseDecoder
    }
}

/// Protocol for encoding request body parameters.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol BodyEncoder {
    /// Encodes parameters into request body data.
    ///
    /// - Parameter parameters: The parameters to encode
    /// - Returns: Encoded data, or nil if encoding fails
    func encode(_ parameters: [String: Any]) -> Data?
}

/// JSON body encoder implementation.
///
/// **Access Control:**
/// - Internal struct: Used within the infrastructure module
struct JSONBodyEncoder: BodyEncoder {
    /// Encodes parameters as JSON data.
    ///
    /// - Parameter parameters: The parameters to encode
    /// - Returns: JSON-encoded data, or nil if encoding fails
    func encode(_ parameters: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: parameters)
    }
}

/// ASCII body encoder implementation (for form-encoded data).
///
/// **Access Control:**
/// - Internal struct: Used within the infrastructure module
struct AsciiBodyEncoder: BodyEncoder {
    /// Encodes parameters as ASCII form-encoded data.
    ///
    /// - Parameter parameters: The parameters to encode
    /// - Returns: ASCII-encoded data, or nil if encoding fails
    func encode(_ parameters: [String: Any]) -> Data? {
        return parameters.queryString.data(using: String.Encoding.ascii, allowLossyConversion: true)
    }
}

/// Protocol for requestable endpoints.
///
/// **Specification Interpretation:**
/// This protocol defines the contract for endpoints that can generate URLRequests.
/// It abstracts the details of URL construction, parameter encoding, and header management.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol Requestable {
    var path: String { get }
    var isFullPath: Bool { get }
    var method: HTTPMethodType { get }
    var headerParameters: [String: String] { get }
    var queryParametersEncodable: Encodable? { get }
    var queryParameters: [String: Any] { get }
    var bodyParametersEncodable: Encodable? { get }
    var bodyParameters: [String: Any] { get }
    var bodyEncoder: BodyEncoder { get }
    
    func urlRequest(with networkConfig: NetworkConfigurable) throws -> URLRequest
}

protocol ResponseRequestable: Requestable {
    associatedtype Response
    
    var responseDecoder: ResponseDecoder { get }
}

enum RequestGenerationError: Error {
    case components
}

extension Requestable {
    
    func url(with config: NetworkConfigurable) throws -> URL {

        let baseURL = config.baseURL.absoluteString.last != "/"
        ? config.baseURL.absoluteString + "/"
        : config.baseURL.absoluteString
        let endpoint = isFullPath ? path : baseURL.appending(path)
        
        guard var urlComponents = URLComponents(
            string: endpoint
        ) else { throw RequestGenerationError.components }
        var urlQueryItems = [URLQueryItem]()

        let queryParameters = try queryParametersEncodable?.toDictionary() ?? self.queryParameters
        queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: "\($0.value)"))
        }
        config.queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: $0.value))
        }
        urlComponents.queryItems = !urlQueryItems.isEmpty ? urlQueryItems : nil
        guard let url = urlComponents.url else { throw RequestGenerationError.components }
        return url
    }
    
    func urlRequest(with config: NetworkConfigurable) throws -> URLRequest {
        
        let url = try self.url(with: config)
        var urlRequest = URLRequest(url: url)
        var allHeaders: [String: String] = config.headers
        headerParameters.forEach { allHeaders.updateValue($1, forKey: $0) }

        let bodyParameters = try bodyParametersEncodable?.toDictionary() ?? self.bodyParameters
        if !bodyParameters.isEmpty {
            urlRequest.httpBody = bodyEncoder.encode(bodyParameters)
        }
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = allHeaders
        return urlRequest
    }
}

private extension Dictionary {
    var queryString: String {
        return self.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
    }
}

private extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: data)
        return jsonData as? [String : Any]
    }
}
