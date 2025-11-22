//
//  City.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Domain entity representing a city with its current weather information.
///
/// **Specification Interpretation:**
/// This is the core domain model used throughout the application. It represents a city
/// with formatted weather data suitable for display in the UI. All data is formatted
/// as strings to ensure consistent presentation regardless of the source.
///
/// **Access Control:**
/// - Public struct: Exposed for use across modules and testing
/// - Public properties: All fields are immutable and publicly accessible
/// - Conforms to Identifiable: Enables SwiftUI list rendering
/// - Conforms to Equatable: Enables comparison and testing
/// - Conforms to Hashable: Enables use in Hashable collections and navigation routes
public struct City: Identifiable, Equatable, Hashable {
    /// Unique identifier for the city (typically "CityName, CountryCode")
    public let id: String
    
    /// Human-readable city name with country code (e.g., "London, GB")
    public let displayName: String
    
    /// Formatted temperature string (e.g., "15°")
    public let temperature: String
    
    /// Formatted humidity percentage (e.g., "87%")
    public let humidity: String
    
    /// Formatted wind speed (e.g., "2.5 m/s")
    public let wind: String
    
    /// Weather condition description (e.g., "Broken clouds")
    public let description: String
    
    /// Optional URL to the weather icon image
    public let iconURL: URL?
    
    /// Timestamp when the weather data was last updated
    public let updatedAt: Date

    /// Initializes a new City instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the city
    ///   - displayName: Human-readable city name
    ///   - temperature: Formatted temperature string
    ///   - humidity: Formatted humidity percentage
    ///   - wind: Formatted wind speed
    ///   - description: Weather condition description
    ///   - iconURL: Optional weather icon URL
    ///   - updatedAt: Last update timestamp
    public init(
        id: String,
        displayName: String,
        temperature: String,
        humidity: String,
        wind: String,
        description: String,
        iconURL: URL?,
        updatedAt: Date
    ) {
        self.id = id
        self.displayName = displayName
        self.temperature = temperature
        self.humidity = humidity
        self.wind = wind
        self.description = description
        self.iconURL = iconURL
        self.updatedAt = updatedAt
    }
}

