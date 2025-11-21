import Foundation

public final class DeleteCityUseCase {
    private let repository: CitiesRepository

    public init(repository: CitiesRepository) {
        self.repository = repository
    }

    public func execute(city: City) async throws {
        try await repository.delete(city)
    }
}

