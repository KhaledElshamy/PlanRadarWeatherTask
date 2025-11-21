import Foundation

public final class FetchCitiesUseCase {
    private let repository: CitiesRepository

    public init(repository: CitiesRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [City] {
        try await repository.fetchSavedCities()
    }
}

