//
//  WeatherIconRepositoryImpl.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation

/// Concrete implementation of the `WeatherIconRepository` protocol.
///
/// **Specification Interpretation:**
/// This repository handles fetching weather icon images from the image API.
/// It uses the `DataTransferService` configured with the images base URL
/// to make network requests for icon data.
///
/// **Access Control:**
/// - Internal class: Used within the data layer
/// - Final class: Prevents inheritance for better performance and clarity
final class WeatherIconRepositoryImpl: WeatherIconRepository {
    
    /// Custom errors that can occur during icon fetching.
    ///
    /// **Access Control:**
    /// - Internal enum: Used within the repository implementation
    enum WeatherIconRepositoryError: LocalizedError {
        case invalidIconCode(String)
        case iconNotFound(String)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidIconCode(let code):
                return "Invalid icon code: \(code)"
            case .iconNotFound(let code):
                return "Weather icon '\(code)' was not found."
            case .networkError(let error):
                return "Failed to fetch weather icon: \(error.localizedDescription)"
            }
        }
    }
    
    /// The data transfer service for making network requests.
    private let network: DataTransferService
    
    /// Initializes the repository with a data transfer service.
    ///
    /// **Specification:** The network service should be configured with
    /// the images base URL to ensure correct endpoint resolution.
    ///
    /// - Parameter network: The data transfer service for network operations
    init(network: DataTransferService) {
        self.network = network
    }
    
    /// Fetches weather icon image data for a given icon code.
    ///
    /// **Specification:** Validates the icon code, constructs the endpoint,
    /// and fetches the image data. Handles network errors and missing icons.
    ///
    /// - Parameter iconCode: The weather icon code (e.g., "01d", "02n")
    /// - Returns: The image data as `Data`
    /// - Throws: `WeatherIconRepositoryError` if the request fails
    func fetchWeatherIcon(iconCode: String) async throws -> Data {
        // Validate icon code
        guard !iconCode.isEmpty else {
            throw WeatherIconRepositoryError.invalidIconCode(iconCode)
        }
        
        // Create endpoint
        let endpoint = WeatherIconEndpoint.weatherIcon(iconCode: iconCode)
        
        do {
            // Fetch image data
            let imageData: Data = try await network.request(with: endpoint)
            return imageData
        } catch let networkError as NetworkError {
            if networkError.hasStatusCode(404) {
                throw WeatherIconRepositoryError.iconNotFound(iconCode)
            }
            throw WeatherIconRepositoryError.networkError(networkError)
        } catch {
            throw WeatherIconRepositoryError.networkError(error)
        }
    }
}

