//
//  WeatherInfoModel+Mapping.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

/// Extension for the auto-generated `WeatherInfoModel` to provide mapping and utility methods.
///
/// **Specification Interpretation:**
/// This extension provides methods to convert between Core Data models and domain entities.
/// It handles the mapping of weather data, including request date/time for historical tracking.
///
/// **Access Control:**
/// - Internal extension: Used within the data layer
extension WeatherInfoModel {
    func apply(city: City, requestDate: Date = Date()) {
        descriptionInfo = city.description
        humidity = city.humidity
        temperature = city.temperature
        wind = city.wind
        imageURL = city.iconURL?.absoluteString
        timeTemp = city.updatedAt
        // Store request date/time for historical tracking
        // Using KVC to safely set the attribute (will work once added to Core Data model)
        // Check if the attribute exists before setting to avoid crashes
        if entity.attributesByName.keys.contains("requestDateTime") {
            setValue(requestDate, forKey: "requestDateTime")
        }
    }

    func domainCity(displayName: String) -> City? {
        guard let descriptionInfo = descriptionInfo,
              let humidity = humidity,
              let temperature = temperature,
              let wind = wind,
              let updatedAt = timeTemp else {
            return nil
        }

        let iconURL = imageURL.flatMap(URL.init(string:))

        return City(
            id: displayName,
            displayName: displayName,
            temperature: temperature,
            humidity: humidity,
            wind: wind,
            description: descriptionInfo,
            iconURL: iconURL,
            updatedAt: updatedAt
        )
    }
    
    /// Converts the `WeatherInfoModel` to a `CityHistoryEntry` domain entity.
    ///
    /// **Specification:** Maps Core Data weather information to a historical entry,
    /// including both the request date/time and the weather date/time.
    ///
    /// - Parameter cityName: The name of the city
    /// - Returns: A `CityHistoryEntry` domain entity, or `nil` if essential data is missing
    func domainHistoryEntry(cityName: String) -> CityHistoryEntry? {
        guard let descriptionInfo = descriptionInfo,
              let humidity = humidity,
              let temperature = temperature,
              let wind = wind,
              let weatherDate = timeTemp else {
            return nil
        }
        
        // Using KVC to safely read the attribute (will work once added to Core Data model)
        // Fallback to weatherDate if requestDateTime doesn't exist yet
        let requestDate: Date
        if entity.attributesByName.keys.contains("requestDateTime"),
           let date = value(forKey: "requestDateTime") as? Date {
            requestDate = date
        } else {
            requestDate = weatherDate
        }
        
        let iconURL = imageURL.flatMap(URL.init(string:))
        
        // Create unique ID from city name and request date
        let id = "\(cityName)_\(requestDate.timeIntervalSince1970)"
        
        return CityHistoryEntry(
            id: id,
            cityName: cityName,
            temperature: temperature,
            description: descriptionInfo,
            requestDate: requestDate,
            weatherDate: weatherDate,
            humidity: humidity,
            wind: wind,
            iconURL: iconURL
        )
    }
}

