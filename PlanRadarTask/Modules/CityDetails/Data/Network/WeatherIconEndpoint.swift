//
//  WeatherIconEndpoint.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation

/// Endpoint definitions for weather icon image requests.
///
/// **Specification Interpretation:**
/// This struct provides endpoint configuration for fetching weather icons
/// from the OpenWeatherMap image API. The endpoint path follows the format:
/// `img/w/{iconCode}.png`
///
/// **Access Control:**
/// - Internal struct: Used within the data layer
struct WeatherIconEndpoint {
    /// Creates an endpoint for fetching a weather icon by icon code.
    ///
    /// **Specification:** The icon code should be in the format "01d", "02n", etc.
    /// The endpoint will construct the path as `img/w/{iconCode}.png`.
    /// Uses `RawDataResponseDecoder` to return raw image data without JSON decoding.
    ///
    /// - Parameter iconCode: The weather icon code (e.g., "01d", "02n")
    /// - Returns: An `Endpoint` configured for fetching the icon image
    static func weatherIcon(iconCode: String) -> Endpoint<Data> {
        return Endpoint(
            path: "img/w/\(iconCode).png",
            method: .get,
            responseDecoder: RawDataResponseDecoder()
        )
    }
}

