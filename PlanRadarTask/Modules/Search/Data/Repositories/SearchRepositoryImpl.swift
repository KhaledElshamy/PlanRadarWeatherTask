import Foundation

final class SearchRepositoryImpl: SearchRepository {

    enum SearchRepositoryError: LocalizedError {
        case cityNotFound(String)

        var errorDescription: String? {
            switch self {
            case .cityNotFound(let name):
                return "\(name) was not found. Check the spelling and try again."
            }
        }
    }

    private let network: DataTransferService

    init(network: DataTransferService) {
        self.network = network
    }

    func searchCity(named name: String) async throws -> City {
        let endpoint = SearchEndpoint.search(for: name)
        do {
            let response: CityResponseDTO = try await network.request(with: endpoint)
            return try response.toDomain()
        } catch let networkError as NetworkError where networkError.hasStatusCode(404) {
            throw SearchRepositoryError.cityNotFound(name)
        }
    }
}

