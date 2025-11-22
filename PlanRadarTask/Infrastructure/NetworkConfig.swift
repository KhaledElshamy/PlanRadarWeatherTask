//
//  NetworkConfig.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Protocol for network configuration.
///
/// **Specification Interpretation:**
/// This protocol defines the configuration needed for network requests: base URL,
/// default headers, and default query parameters that are applied to all requests.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol NetworkConfigurable {
    /// The base URL for all API requests
    var baseURL: URL { get }
    
    /// Default headers to include in all requests
    var headers: [String: String] { get }
    
    /// Default query parameters to include in all requests
    var queryParameters: [String: String] { get }
}

/// Default implementation of NetworkConfigurable.
///
/// **Specification Interpretation:**
/// This struct provides a concrete implementation for API network configuration.
/// It's used to configure the network service with base URLs, authentication headers,
/// and common query parameters (like API keys).
///
/// **Access Control:**
/// - Internal struct: Used within the infrastructure module
struct ApiDataNetworkConfig: NetworkConfigurable {
    /// The base URL for API requests
    let baseURL: URL
    
    /// Default headers for all requests
    let headers: [String: String]
    
    /// Default query parameters for all requests (e.g., API key)
    let queryParameters: [String: String]
    
     init(
        baseURL: URL,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:]
     ) {
        self.baseURL = baseURL
        self.headers = headers
        self.queryParameters = queryParameters
    }
}
