//
//  AddCityUseCase.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Use case for adding a city to local storage.
///
/// **Specification Interpretation:**
/// This use case encapsulates the business logic for persisting cities. After a successful
/// search, the user can save the city to their local list for quick access later.
///
/// **Access Control:**
/// - Public class: Exposed for use across modules and testing
/// - Private storage: Dependency is encapsulated
/// - Internal init: Only accessible within the module (used by DI container)
/// - Public execute method: Main entry point for the use case
public final class AddCityUseCase {
    private let storage: CitiesStorage

    /// Initializes the use case with a storage dependency.
    ///
    /// - Parameter storage: The storage implementation to use for persistence
    init(storage: CitiesStorage) {
        self.storage = storage
    }

    /// Executes the use case to save a city.
    ///
    /// **Specification:** Saves the city to local persistent storage. If a city with
    /// the same name already exists, it will be updated with the new weather data.
    ///
    /// - Parameter city: The city entity to save
    /// - Throws: Storage errors if the save operation fails
    public func execute(city: City) async throws {
        try await storage.save(city)
    }
}

