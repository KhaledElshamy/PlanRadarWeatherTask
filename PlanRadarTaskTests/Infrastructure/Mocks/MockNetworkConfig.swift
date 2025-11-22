//
//  MockNetworkConfig.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of NetworkConfigurable for testing.
///
/// **Access Control:**
/// - Internal struct: Used within test module
struct MockNetworkConfig: NetworkConfigurable {
    let baseURL: URL
    let headers: [String: String]
    let queryParameters: [String: String]
    
    /// Initializes the mock config.
    ///
    /// - Parameters:
    ///   - baseURL: Base URL for requests (default: https://api.example.com)
    ///   - headers: Default headers (default: empty)
    ///   - queryParameters: Default query parameters (default: empty)
    init(
        baseURL: URL = URL(string: "https://api.example.com")!,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.queryParameters = queryParameters
    }
}

