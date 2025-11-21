import Foundation

public final class AddCityUseCase {
    private let storage: CitiesStorage

    init(storage: CitiesStorage) {
        self.storage = storage
    }

    public func execute(city: City) async throws {
        try await storage.save(city)
    }
}

