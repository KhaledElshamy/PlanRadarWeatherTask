import Foundation

protocol CitiesStorage {
    func fetchCities() async throws -> [City]
    func save(_ city: City) async throws
    func delete(_ city: City) async throws
}

