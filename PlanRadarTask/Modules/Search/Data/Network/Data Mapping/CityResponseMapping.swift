import Foundation

enum CitiesMappingError: Error, LocalizedError {
    case missingWeatherInfo
    case invalidTemperature(Double)
    case invalidImageURL(String)

    var errorDescription: String? {
        switch self {
        case .missingWeatherInfo:
            return "No weather data available for the requested location."
        case let .invalidTemperature(value):
            return "Invalid temperature value: \(value)"
        case let .invalidImageURL(value):
            return "Could not hydrate image URL: \(value)"
        }
    }
}

// MARK: - CityResponseDTO to Domain Mapping

extension CityResponseDTO {
    func toDomain() throws -> City {
        guard
            let name = name,
            let sys = sys,
            let weatherInfo = weather?.first ?? weather?.first,
            let updatedAtTimestamp = dt
        else {
            throw CitiesMappingError.missingWeatherInfo
        }

        let displayName = "\(name), \(sys.country ?? "N/A")"
        let temperatureString = main?.temp.map { String(format: "%.0f°", $0) } ?? "--"
        let humidityString = "\(main?.humidity ?? 0)%"
        let windString = wind?.speed.map { String(format: "%.1f m/s", $0) } ?? "—"
        let description = (weatherInfo.description ?? "Unknown").capitalized
        let updatedAt = Date(timeIntervalSince1970: TimeInterval(updatedAtTimestamp))

        let iconURL: URL?
        if let icon = weatherInfo.icon, !icon.isEmpty {
            let iconPath = "https://openweathermap.org/img/wn/\(icon)@2x.png"
            iconURL = URL(string: iconPath)
            if iconURL == nil {
                throw CitiesMappingError.invalidImageURL(iconPath)
            }
        } else {
            iconURL = nil
        }

        return City(
            id: displayName,
            displayName: displayName,
            temperature: temperatureString,
            humidity: humidityString,
            wind: windString,
            description: description,
            iconURL: iconURL,
            updatedAt: updatedAt
        )
    }
}

