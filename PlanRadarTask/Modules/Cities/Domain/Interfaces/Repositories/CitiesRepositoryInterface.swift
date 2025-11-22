//
//  CitiesRepositoryInterface.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Repository protocol for city persistence operations.
///
/// **Specification Interpretation:**
/// This protocol defines the contract for city data access, abstracting the underlying
/// storage implementation. This enables easy testing through mock implementations and
/// allows swapping storage backends without affecting the domain layer.
///
/// **Access Control:**
/// - Public protocol: Exposed for implementation across modules
/// - All methods are async/throws: Supports modern Swift concurrency and error handling
public protocol CitiesRepository {
    /// Fetches all cities saved locally from persistent storage.
    ///
    /// **Specification:** Returns an array of all cities currently stored in the database.
    /// The cities are returned in the order they were last updated (most recent first).
    ///
    /// - Returns: An array of City entities
    /// - Throws: Storage errors if the fetch operation fails
    func fetchSavedCities() async throws -> [City]

    /// Deletes a city from the local persistent store.
    ///
    /// **Specification:** Removes the specified city and all associated weather data
    /// from the database. The operation is cascaded to related entities.
    ///
    /// - Parameter city: The city entity to delete
    /// - Throws: Storage errors if the deletion operation fails
    func delete(_ city: City) async throws
}

