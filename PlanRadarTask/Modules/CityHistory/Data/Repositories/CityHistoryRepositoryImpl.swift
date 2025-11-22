//
//  CityHistoryRepositoryImpl.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

/// Concrete implementation of the `CityHistoryRepository` protocol.
///
/// **Specification Interpretation:**
/// This repository handles fetching historical weather data from Core Data.
/// It queries all weather entries for a specific city and maps them to domain entities.
///
/// **Access Control:**
/// - Internal class: Used within the data layer
/// - Final class: Prevents inheritance for better performance and clarity
final class CityHistoryRepositoryImpl: CityHistoryRepository {
    
    /// The Core Data managed object context.
    private let context: NSManagedObjectContext
    
    /// Initializes the repository with a Core Data context.
    ///
    /// - Parameter context: The `NSManagedObjectContext` to use for operations
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Fetches all historical entries for a specific city.
    ///
    /// **Specification:** Queries Core Data for all weather entries associated with
    /// the given city name, sorted by request date (most recent first).
    ///
    /// - Parameter cityName: The name of the city to fetch history for
    /// - Returns: An array of `CityHistoryEntry` entities
    /// - Throws: An error if the fetch operation fails
    func fetchHistory(for cityName: String) async throws -> [CityHistoryEntry] {
        return try await context.perform {
            // Fetch all CityModel entries for this city
            let cityRequest: NSFetchRequest<CityModel> = CityModel.fetchRequest()
            cityRequest.predicate = NSPredicate(format: "name == %@", cityName)
            let cities = try self.context.fetch(cityRequest)
            
            // Collect all weather entries from all city instances
            var entries: [CityHistoryEntry] = []
            
            for cityModel in cities {
                guard let weatherSet = cityModel.weatherSet?.allObjects as? [WeatherInfoModel] else {
                    continue
                }
                
                for weather in weatherSet {
                    if let entry = weather.domainHistoryEntry(cityName: cityName) {
                        entries.append(entry)
                    }
                }
            }
            
            // Sort by request date (most recent first)
            return entries.sorted(by: { $0.requestDate > $1.requestDate })
        }
    }
}

