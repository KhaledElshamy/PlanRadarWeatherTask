//
//  CityFactory.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Factory for creating test City instances.
///
/// **Access Control:**
/// - Internal struct: Used within test module
enum CityFactory {
    /// Creates a test city with default values.
    ///
    /// - Parameters:
    ///   - id: City identifier (default: "london_gb")
    ///   - displayName: Display name (default: "London, GB")
    ///   - temperature: Temperature string (default: "15°")
    ///   - humidity: Humidity string (default: "87%")
    ///   - wind: Wind speed string (default: "2.5 m/s")
    ///   - description: Weather description (default: "Broken clouds")
    ///   - iconURL: Icon URL (default: URL for "01d" icon)
    ///   - updatedAt: Update timestamp (default: current date)
    /// - Returns: A City instance with the specified values
    static func makeCity(
        id: String = "london_gb",
        displayName: String = "London, GB",
        temperature: String = "15°",
        humidity: String = "87%",
        wind: String = "2.5 m/s",
        description: String = "Broken clouds",
        iconURL: URL? = URL(string: "https://openweathermap.org/img/w/01d.png"),
        updatedAt: Date = Date()
    ) -> City {
        City(
            id: id,
            displayName: displayName,
            temperature: temperature,
            humidity: humidity,
            wind: wind,
            description: description,
            iconURL: iconURL,
            updatedAt: updatedAt
        )
    }
    
    /// Creates multiple test cities.
    ///
    /// - Parameter count: Number of cities to create
    /// - Returns: Array of City instances
    static func makeCities(count: Int) -> [City] {
        (0..<count).map { index in
            makeCity(
                id: "city_\(index)",
                displayName: "City \(index), CC",
                updatedAt: Date().addingTimeInterval(TimeInterval(-index * 3600))
            )
        }
    }
}

