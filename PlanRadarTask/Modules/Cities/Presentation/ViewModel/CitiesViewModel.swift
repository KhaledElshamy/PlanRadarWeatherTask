//
//  CitiesViewModel.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import Combine

@MainActor
final class CitiesViewModel: ObservableObject {

    @Published private(set) var cities: [City] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchUseCase: FetchCitiesUseCase
    private let deleteUseCase: DeleteCityUseCase

    init(
        fetchUseCase: FetchCitiesUseCase,
        deleteUseCase: DeleteCityUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
    }

    func loadCities() {
        Task {
            await fetchSavedCities()
        }
    }

    func deleteCity(at indexSet: IndexSet) {
        let citiesToRemove = indexSet.compactMap { cities[safe: $0] }
        Task {
            do {
                for city in citiesToRemove {
                    try await deleteUseCase.execute(city: city)
                }
                await fetchSavedCities()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchSavedCities() async {
        isLoading = true
        defer { isLoading = false }
        do {
            cities = try await fetchUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        (indices.contains(index) ? self[index] : nil)
    }
}
