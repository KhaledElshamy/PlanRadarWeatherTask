//
//  WeatherIconRepository.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation

/// Protocol defining the interface for fetching weather icon images.
///
/// **Specification Interpretation:**
/// This repository provides access to weather icon images from the image API.
/// It abstracts the network layer and provides a clean interface for fetching
/// icon data based on the icon code.
///
/// **Access Control:**
/// - Public protocol: Exposed for use across modules and testing
public protocol WeatherIconRepository {
    /// Fetches weather icon image data for a given icon code.
    ///
    /// **Specification:** The icon code should be in the format "01d", "02n", etc.
    /// The repository will construct the appropriate URL and fetch the image data.
    ///
    /// - Parameter iconCode: The weather icon code (e.g., "01d", "02n")
    /// - Returns: The image data as `Data`
    /// - Throws: An error if the network request fails or the icon is not found
    func fetchWeatherIcon(iconCode: String) async throws -> Data
}

