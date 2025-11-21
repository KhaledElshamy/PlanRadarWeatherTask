import Foundation
import CoreData

final class CoreDataCitiesStorage: CitiesStorage {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchCities() async throws -> [City] {
        return try await context.perform {
            let request: NSFetchRequest<CityModel> = CityModel.fetchRequest()
            let results = try self.context.fetch(request)
            let cities = results.compactMap { $0.domainCity() }
            return cities.sorted(by: { $0.updatedAt > $1.updatedAt })
        }
    }

    func save(_ city: City) async throws {
        try await context.perform {
            let request: NSFetchRequest<CityModel> = CityModel.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", city.displayName)
            let existing = try self.context.fetch(request)

            if let model = existing.first {
                model.update(from: city, in: self.context)
            } else {
                let model = CityModel(context: self.context)
                model.populate(from: city, in: self.context)
            }

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

