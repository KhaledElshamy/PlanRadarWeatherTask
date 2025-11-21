import Foundation

extension WeatherInfoModel {
    func apply(city: City) {
        descriptionInfo = city.description
        humidity = city.humidity
        temperature = city.temperature
        wind = city.wind
        imageURL = city.iconURL?.absoluteString
        timeTemp = city.updatedAt
    }

    func domainCity(displayName: String) -> City? {
        guard let descriptionInfo = descriptionInfo,
              let humidity = humidity,
              let temperature = temperature,
              let wind = wind,
              let updatedAt = timeTemp else {
            return nil
        }

        let iconURL = imageURL.flatMap(URL.init(string:))

        return City(
            id: displayName,
            displayName: displayName,
            temperature: temperature,
            humidity: humidity,
            wind: wind,
            description: descriptionInfo,
            iconURL: iconURL,
            updatedAt: updatedAt
        )
    }
}

