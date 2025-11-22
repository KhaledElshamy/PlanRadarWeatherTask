//
//  CityModel+Mapping.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

/// Extension for the auto-generated `CityModel` to provide mapping and utility methods.
///
/// **Specification Interpretation:**
/// This extension provides methods to convert between Core Data models and domain entities.
/// It handles the mapping of city data and associated weather information.
///
/// **Access Control:**
/// - Internal extension: Used within the data layer
extension CityModel {
    var primaryWeather: WeatherInfoModel? {
        (weatherSet?.allObjects as? [WeatherInfoModel])?.first
    }

    func populate(from city: City, in context: NSManagedObjectContext, requestDate: Date = Date()) {
        name = city.displayName
        let weather = WeatherInfoModel(context: context)
        weather.apply(city: city, requestDate: requestDate)
        addWeatherInfo(weather)
    }

    func update(from city: City, in context: NSManagedObjectContext) {
        name = city.displayName
        if let weather = primaryWeather {
            weather.apply(city: city)
        } else {
        let weather = WeatherInfoModel(context: context)
        weather.apply(city: city)
        addWeatherInfo(weather)
        }
    }

    func domainCity() -> City? {
        guard let displayName = name,
              let weather = primaryWeather else {
            return nil
        }
        return weather.domainCity(displayName: displayName)
    }

    private func addWeatherInfo(_ value: WeatherInfoModel) {
        let set = mutableSetValue(forKey: "weatherSet")
        set.add(value)
        value.city = self
    }
}

