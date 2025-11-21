import Foundation

public final class SearchCityUseCase {
    private let repository: SearchRepository

    public init(repository: SearchRepository) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> City {
        try await repository.searchCity(named: query)
    }
}

