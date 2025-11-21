import Foundation
import CoreData

extension CityModel {
    var primaryWeather: WeatherInfoModel? {
        (weatherSet?.allObjects as? [WeatherInfoModel])?.first
    }

    func populate(from city: City, in context: NSManagedObjectContext) {
        name = city.displayName
        let weather = WeatherInfoModel(context: context)
        weather.apply(city: city)
        addWeatherInfo(weather)
    }

    func update(from city: City, in context: NSManagedObjectContext) {
        name = city.displayName
        if let weather = primaryWeather {
            weather.apply(city: city)
        } else {
        let weather = WeatherInfoModel(context: context)
        weather.apply(city: city)
        addWeatherInfo(weather)
        }
    }

    func domainCity() -> City? {
        guard let displayName = name,
              let weather = primaryWeather else {
            return nil
        }
        return weather.domainCity(displayName: displayName)
    }

    private func addWeatherInfo(_ value: WeatherInfoModel) {
        let set = mutableSetValue(forKey: "weatherSet")
        set.add(value)
        value.city = self
    }
}

