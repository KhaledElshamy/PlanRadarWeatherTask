//
//  Persistence.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        let samples: [City] = [
            City(id: "London, UK", displayName: "London, UK", temperature: "21°", humidity: "60%", wind: "6 km/h", description: "Clear sky", iconURL: URL(string: "https://openweathermap.org/img/wn/01d@2x.png"), updatedAt: Date()),
            City(id: "Paris, FR", displayName: "Paris, FR", temperature: "19°", humidity: "65%", wind: "4 km/h", description: "Cloudy", iconURL: URL(string: "https://openweathermap.org/img/wn/04d@2x.png"), updatedAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!)
        ]
        for sample in samples {
            let model = CityModel(context: context)
            model.name = sample.displayName
            let weather = WeatherInfoModel(context: context)
            weather.descriptionInfo = sample.description
            weather.humidity = sample.humidity
            weather.temperature = sample.temperature
            weather.wind = sample.wind
            weather.imageURL = sample.iconURL?.absoluteString
            weather.timeTemp = sample.updatedAt
            weather.city = model
        }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PlanRadarTask")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
