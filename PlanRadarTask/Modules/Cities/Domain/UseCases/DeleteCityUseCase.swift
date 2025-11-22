//
//  DeleteCityUseCase.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Use case for deleting a city from local storage.
///
/// **Specification Interpretation:**
/// This use case encapsulates the business logic for removing cities. It ensures
/// that deletion operations are properly handled and that related data (weather info)
/// is also removed through cascading deletes.
///
/// **Access Control:**
/// - Public class: Exposed for use across modules and testing
/// - Private repository: Dependency is encapsulated
/// - Public execute method: Main entry point for the use case
public final class DeleteCityUseCase {
    private let repository: CitiesRepository

    /// Initializes the use case with a repository dependency.
    ///
    /// - Parameter repository: The repository implementation to use for data access
    public init(repository: CitiesRepository) {
        self.repository = repository
    }

    /// Executes the use case to delete a city.
    ///
    /// **Specification:** Removes the specified city and all associated weather data
    /// from local storage. The operation is permanent and cannot be undone.
    ///
    /// - Parameter city: The city entity to delete
    /// - Throws: Storage errors if the deletion operation fails
    public func execute(city: City) async throws {
        try await repository.delete(city)
    }
}

