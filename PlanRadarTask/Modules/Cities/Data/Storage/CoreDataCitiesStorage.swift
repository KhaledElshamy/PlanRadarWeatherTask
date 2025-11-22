//
//  CoreDataCitiesStorage.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

/// Core Data implementation of the `CitiesStorage` protocol.
///
/// **Specification Interpretation:**
/// This class provides persistence operations for cities using Core Data. It handles
/// saving, fetching, and deleting city data. Each save operation creates a new entry
/// to maintain historical data with request date/time tracking.
///
/// **Access Control:**
/// - Internal class: Used within the data layer
/// - Final class: Prevents inheritance for better performance and clarity
final class CoreDataCitiesStorage: CitiesStorage {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchCities() async throws -> [City] {
        return try await context.perform {
            let request: NSFetchRequest<CityModel> = CityModel.fetchRequest()
            let results = try self.context.fetch(request)
            
            // Group by city name and get the most recent entry for each city
            var uniqueCities: [String: City] = [:]
            
            for cityModel in results {
                guard let city = cityModel.domainCity() else { continue }
                
                // If we haven't seen this city, or this one is more recent, use it
                if let existing = uniqueCities[city.displayName] {
                    if city.updatedAt > existing.updatedAt {
                        uniqueCities[city.displayName] = city
                    }
                } else {
                    uniqueCities[city.displayName] = city
                }
            }
            
            // Return unique cities sorted by most recent update
            return Array(uniqueCities.values).sorted(by: { $0.updatedAt > $1.updatedAt })
        }
    }

    func save(_ city: City) async throws {
        try await context.perform {
            // Always create a new entry for historical tracking
            // The request date is set to now to track when the data was requested
            let model = CityModel(context: self.context)
            model.populate(from: city, in: self.context, requestDate: Date())
            
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    func delete(_ city: City) async throws {
        try await context.perform {
            let request: NSFetchRequest<CityModel> = CityModel.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", city.displayName)
            let models = try self.context.fetch(request)
            models.forEach(self.context.delete)
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
}

