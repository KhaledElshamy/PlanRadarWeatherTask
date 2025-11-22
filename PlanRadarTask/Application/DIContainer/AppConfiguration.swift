//
//  AppConfiguration.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Configuration manager that reads application settings from Info.plist.
/// 
/// **Specification Interpretation:**
/// This class provides centralized access to configuration values that are injected
/// at build time through Info.plist substitutions. It ensures type safety by converting
/// string values to appropriate types (URL, String) and validates their presence.
///
/// **Access Control:**
/// - Internal class: Used only within the application module
/// - Private helper methods: Encapsulate validation logic
final class AppConfiguration {
    
    /// The base URL for API requests (e.g., https://api.openweathermap.org)
    /// 
    /// **Specification:** Must be configured in Info.plist via API_BASE_URL key.
    /// Fails fast if missing or invalid to prevent runtime errors.
    lazy var apiBaseURL: URL = {
        url(forKey: "API_BASE_URL", description: "ApiBaseURL")
    }()
    
    /// The base URL for image resources (e.g., https://openweathermap.org)
    /// 
    /// **Specification:** Must be configured in Info.plist via IMAGE_BASE_URL key.
    /// Used for constructing weather icon URLs.
    lazy var imagesBaseURL: URL = {
        url(forKey: "IMAGE_BASE_URL", description: "ImageBaseURL")
    }()

    /// The API key for authenticating requests to the weather service.
    /// 
    /// **Specification:** Must be configured in Secrets.xcconfig and injected into Info.plist
    /// via the API_KEY key. This value should never be committed to source control.
    lazy var apiKey: String = {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !apiKey.isEmpty else {
            fatalError("API_KEY must not be empty in plist")
        }
        return apiKey
    }()

    /// Helper method to safely extract and validate URL values from Info.plist.
    /// 
    /// - Parameters:
    ///   - key: The Info.plist key to read
    ///   - description: Human-readable description for error messages
    /// - Returns: A validated URL instance
    /// - Throws: Fatal error if the key is missing, empty, or invalid
    private func url(forKey key: String, description: String) -> URL {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            fatalError("\(description) must not be empty in plist")
        }
        guard let url = URL(string: value) else {
            fatalError("\(description) must be a valid URL string")
        }
        return url
    }
}

