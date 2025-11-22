//
//  FetchCitiesUseCase.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Protocol for FetchCitiesUseCase to enable testing and dependency injection.
///
/// **Access Control:**
/// - Internal protocol: Used for testing and dependency injection
protocol FetchCitiesUseCaseProtocol {
    func execute() async throws -> [City]
}

/// Use case for fetching all saved cities from local storage.
///
/// **Specification Interpretation:**
/// This use case encapsulates the business logic for retrieving cities. It acts as
/// an intermediary between the presentation layer and the repository, ensuring that
/// the domain layer remains independent of infrastructure concerns.
///
/// **Access Control:**
/// - Public class: Exposed for use across modules and testing
/// - Private repository: Dependency is encapsulated
/// - Public execute method: Main entry point for the use case
public final class FetchCitiesUseCase {
    private let repository: CitiesRepository

    /// Initializes the use case with a repository dependency.
    ///
    /// - Parameter repository: The repository implementation to use for data access
    public init(repository: CitiesRepository) {
        self.repository = repository
    }

    /// Executes the use case to fetch all saved cities.
    ///
    /// **Specification:** Retrieves all cities from local storage, sorted by most
    /// recently updated first.
    ///
    /// - Returns: An array of City entities
    /// - Throws: Storage errors if the fetch operation fails
    public func execute() async throws -> [City] {
        try await repository.fetchSavedCities()
    }
}

// MARK: - Protocol Conformance

extension FetchCitiesUseCase: FetchCitiesUseCaseProtocol {}

