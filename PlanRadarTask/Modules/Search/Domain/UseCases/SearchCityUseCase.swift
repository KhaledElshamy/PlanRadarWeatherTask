//
//  SearchCityUseCase.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Use case for searching city weather information via the API.
///
/// **Specification Interpretation:**
/// This use case encapsulates the business logic for searching cities. It takes a user's
/// search query (city name, postcode, or airport location) and retrieves current weather
/// data from the OpenWeatherMap API.
///
/// **Access Control:**
/// - Public class: Exposed for use across modules and testing
/// - Private repository: Dependency is encapsulated
/// - Public execute method: Main entry point for the use case
public final class SearchCityUseCase {
    private let repository: SearchRepository

    /// Initializes the use case with a repository dependency.
    ///
    /// - Parameter repository: The repository implementation to use for API access
    public init(repository: SearchRepository) {
        self.repository = repository
    }

    /// Executes the use case to search for a city.
    ///
    /// **Specification:** Searches the OpenWeatherMap API for weather data matching
    /// the query string. The query can be a city name, postcode, or airport location.
    /// Returns a City entity with current weather information.
    ///
    /// - Parameter query: The search query string (city name, postcode, or airport)
    /// - Returns: A City entity with current weather data
    /// - Throws: Network errors if the API request fails, or mapping errors if the response is invalid
    public func execute(query: String) async throws -> City {
        try await repository.searchCity(named: query)
    }
}

