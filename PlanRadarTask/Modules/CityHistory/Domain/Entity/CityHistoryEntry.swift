//
//  CityHistoryEntry.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation

/// Domain entity representing a historical weather entry for a city.
///
/// **Specification Interpretation:**
/// This entity represents a single historical weather data point for a city,
/// including the weather information and the date/time when the data was requested.
/// It's used to display the history of weather searches for a specific city.
///
/// **Access Control:**
/// - Public struct: Exposed for use across modules and testing
/// - Public properties: All fields are immutable and publicly accessible
/// - Conforms to Identifiable: Enables SwiftUI list rendering
/// - Conforms to Equatable: Enables comparison and testing
/// - Conforms to Hashable: Enables use in Hashable collections
public struct CityHistoryEntry: Identifiable, Equatable, Hashable {
    /// Unique identifier for the history entry
    public let id: String
    
    /// The city name this entry belongs to
    public let cityName: String
    
    /// Formatted temperature string (e.g., "14°C")
    public let temperature: String
    
    /// Weather condition description (e.g., "Cloudy")
    public let description: String
    
    /// The date and time when this weather data was requested
    public let requestDate: Date
    
    /// The date and time when the weather data was recorded (from API)
    public let weatherDate: Date
    
    /// Formatted humidity percentage (e.g., "87%")
    public let humidity: String
    
    /// Formatted wind speed (e.g., "2.5 m/s")
    public let wind: String
    
    /// Optional URL to the weather icon image
    public let iconURL: URL?
    
    /// Initializes a new CityHistoryEntry instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the entry
    ///   - cityName: The city name
    ///   - temperature: Formatted temperature string
    ///   - description: Weather condition description
    ///   - requestDate: Date when the data was requested
    ///   - weatherDate: Date when the weather data was recorded
    ///   - humidity: Formatted humidity percentage
    ///   - wind: Formatted wind speed
    ///   - iconURL: Optional weather icon URL
    public init(
        id: String,
        cityName: String,
        temperature: String,
        description: String,
        requestDate: Date,
        weatherDate: Date,
        humidity: String,
        wind: String,
        iconURL: URL?
    ) {
        self.id = id
        self.cityName = cityName
        self.temperature = temperature
        self.description = description
        self.requestDate = requestDate
        self.weatherDate = weatherDate
        self.humidity = humidity
        self.wind = wind
        self.iconURL = iconURL
    }
}

