import Foundation

public protocol SearchRepository {
    /// Searches the OpenWeatherMap API for a city matching the given name.
    func searchCity(named name: String) async throws -> City
}

