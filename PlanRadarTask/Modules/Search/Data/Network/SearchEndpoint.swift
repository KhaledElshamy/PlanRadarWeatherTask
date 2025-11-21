import Foundation

struct SearchCityRequestDTO: Encodable {
    let q: String
    let units: String = "metric"
}

struct SearchEndpoint {
    static func search(for name: String) -> Endpoint<CityResponseDTO> {
        let requestDTO = SearchCityRequestDTO(q: name)
        return Endpoint(
            path: "data/2.5/weather",
            method: .get,
            queryParametersEncodable: requestDTO
        )
    }
}

