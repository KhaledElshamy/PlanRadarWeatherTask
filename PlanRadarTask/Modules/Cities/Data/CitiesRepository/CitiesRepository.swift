//
//  CitiesRepository.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

final class CitiesRepositoryImpl: CitiesRepository {

    private let storage: CitiesStorage

    init(storage: CitiesStorage) {
        self.storage = storage
    }

    func fetchSavedCities() async throws -> [City] {
        try await storage.fetchCities()
    }

    func delete(_ city: City) async throws {
        try await storage.delete(city)
    }
}
