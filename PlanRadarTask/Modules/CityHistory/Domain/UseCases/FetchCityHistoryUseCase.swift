//
//  FetchCityHistoryUseCase.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Use case for fetching city history.
///
/// **Specification Interpretation:**
/// This use case encapsulates the business logic for fetching historical weather data
/// for a city. It acts as an intermediary between the presentation layer and the repository,
/// ensuring that the domain layer remains independent of data source details.
///
/// **Access Control:**
/// - Internal class: Used within the domain layer
/// - Final class: Prevents inheritance for better performance and clarity
final class FetchCityHistoryUseCase {
    
    /// The repository for fetching city history.
    private let repository: CityHistoryRepository
    
    /// Initializes the use case with a city history repository.
    ///
    /// - Parameter repository: The repository for fetching city history
    init(repository: CityHistoryRepository) {
        self.repository = repository
    }
    
    /// Executes the use case to fetch city history.
    ///
    /// **Specification:** Fetches all historical weather entries for the given city.
    /// The entries are sorted by request date (most recent first).
    ///
    /// - Parameter cityName: The name of the city to fetch history for
    /// - Returns: An array of `CityHistoryEntry` entities
    /// - Throws: An error if the fetch operation fails
    func execute(cityName: String) async throws -> [CityHistoryEntry] {
        return try await repository.fetchHistory(for: cityName)
    }
}

