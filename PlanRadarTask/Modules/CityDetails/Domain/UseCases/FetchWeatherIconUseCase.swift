//
//  FetchWeatherIconUseCase.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation

/// Protocol for FetchWeatherIconUseCase to enable testing and dependency injection.
///
/// **Access Control:**
/// - Internal protocol: Used for testing and dependency injection
protocol FetchWeatherIconUseCaseProtocol {
    func execute(iconCode: String) async throws -> Data
}

/// Use case for fetching weather icon images.
///
/// **Specification Interpretation:**
/// This use case encapsulates the business logic for fetching weather icons.
/// It acts as an intermediary between the presentation layer and the repository,
/// ensuring that the domain layer remains independent of data source details.
///
/// **Access Control:**
/// - Internal class: Used within the domain layer
/// - Final class: Prevents inheritance for better performance and clarity
final class FetchWeatherIconUseCase {
    
    /// The repository for fetching weather icons.
    private let repository: WeatherIconRepository
    
    /// Initializes the use case with a weather icon repository.
    ///
    /// - Parameter repository: The repository for fetching weather icons
    init(repository: WeatherIconRepository) {
        self.repository = repository
    }
    
    /// Executes the use case to fetch a weather icon.
    ///
    /// **Specification:** Fetches the weather icon image data for the given
    /// icon code. The icon code should be extracted from the city's weather data.
    ///
    /// - Parameter iconCode: The weather icon code (e.g., "01d", "02n")
    /// - Returns: The image data as `Data`
    /// - Throws: An error if the fetch operation fails
    func execute(iconCode: String) async throws -> Data {
        return try await repository.fetchWeatherIcon(iconCode: iconCode)
    }
}

// MARK: - Protocol Conformance

extension FetchWeatherIconUseCase: FetchWeatherIconUseCaseProtocol {}

