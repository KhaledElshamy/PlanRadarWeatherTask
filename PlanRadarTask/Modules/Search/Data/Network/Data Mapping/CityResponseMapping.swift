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
        guard let weatherInfo = weather.first else {
            throw CitiesMappingError.missingWeatherInfo
        }

        let displayName = "\(name), \(sys.country)"
        let temperatureString = String(format: "%.0f°", main.temp)
        let humidityString = "\(main.humidity)%"
        let windString = String(format: "%.1f m/s", wind.speed)
        let description = weatherInfo.description.capitalized
        let updatedAt = Date(timeIntervalSince1970: TimeInterval(dt))

        let iconURL: URL?
        if !weatherInfo.icon.isEmpty {
            let iconPath = "https://openweathermap.org/img/wn/\(weatherInfo.icon)@2x.png"
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

