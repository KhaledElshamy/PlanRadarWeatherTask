import Foundation

public protocol CitiesRepository {
    /// Fetches all cities saved locally (Core Data).
    func fetchSavedCities() async throws -> [City]

    /// Deletes a city from the local store.
    func delete(_ city: City) async throws
}

