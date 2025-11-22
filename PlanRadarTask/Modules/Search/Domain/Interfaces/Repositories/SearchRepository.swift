//
//  SearchRepository.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Repository protocol for searching city weather information.
///
/// **Specification Interpretation:**
/// This protocol defines the contract for city search operations, abstracting the underlying
/// network implementation. This enables easy testing through mock implementations and
/// allows swapping network backends without affecting the domain layer.
///
/// **Access Control:**
/// - Public protocol: Exposed for implementation across modules
/// - All methods are async/throws: Supports modern Swift concurrency and error handling
public protocol SearchRepository {
    /// Searches the OpenWeatherMap API for a city matching the given name.
    ///
    /// **Specification:** Queries the OpenWeatherMap API (https://api.openweathermap.org/data/2.5/weather)
    /// with the provided city name, postcode, or airport location. Returns current weather
    /// data formatted as a City domain entity.
    ///
    /// - Parameter name: The city name, postcode, or airport location to search for
    /// - Returns: A City entity with current weather data
    /// - Throws: Network errors (404 if city not found, network failures, etc.) or mapping errors
    func searchCity(named name: String) async throws -> City
}

