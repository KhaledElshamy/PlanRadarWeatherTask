//
//  CityHistoryRepository.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Protocol defining the interface for managing city history data.
///
/// **Specification Interpretation:**
/// This repository provides access to historical weather data for cities.
/// It abstracts the storage layer and provides a clean interface for fetching
/// historical entries based on city name.
///
/// **Access Control:**
/// - Public protocol: Exposed for use across modules and testing
public protocol CityHistoryRepository {
    /// Fetches all historical entries for a specific city.
    ///
    /// **Specification:** Returns all historical weather entries for the given city,
    /// sorted by request date (most recent first).
    ///
    /// - Parameter cityName: The name of the city to fetch history for
    /// - Returns: An array of `CityHistoryEntry` entities
    /// - Throws: An error if the fetch operation fails
    func fetchHistory(for cityName: String) async throws -> [CityHistoryEntry]
}

