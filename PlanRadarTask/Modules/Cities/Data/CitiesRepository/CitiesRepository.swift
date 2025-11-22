//
//  CitiesRepository.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Concrete implementation of the CitiesRepository protocol.
///
/// **Specification Interpretation:**
/// This class implements the repository pattern, providing a clean abstraction over
/// the storage layer. It delegates all persistence operations to the CitiesStorage
/// protocol, ensuring that the domain layer remains decoupled from Core Data specifics.
///
/// **Access Control:**
/// - Internal class: Only accessible within the module (used by DI container)
/// - Private storage: Dependency is encapsulated
/// - Internal init: Only accessible within the module
/// - Public protocol conformance: Methods are accessible through the protocol
final class CitiesRepositoryImpl: CitiesRepository {

    /// The storage implementation used for persistence operations
    private let storage: CitiesStorage

    /// Initializes the repository with a storage dependency.
    ///
    /// - Parameter storage: The storage implementation to use
    init(storage: CitiesStorage) {
        self.storage = storage
    }

    /// Fetches all saved cities from local storage.
    ///
    /// - Returns: An array of City entities
    /// - Throws: Storage errors if the fetch operation fails
    func fetchSavedCities() async throws -> [City] {
        try await storage.fetchCities()
    }

    /// Deletes a city from local storage.
    ///
    /// - Parameter city: The city entity to delete
    /// - Throws: Storage errors if the deletion operation fails
    func delete(_ city: City) async throws {
        try await storage.delete(city)
    }
}
