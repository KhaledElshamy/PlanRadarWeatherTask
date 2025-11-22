//
//  CitiesViewModel.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import Combine

// MARK: - View Model Protocols

/// Protocol defining input actions for the cities view model.
///
/// **Specification Interpretation:**
/// This protocol defines all user actions and triggers that can be sent to the view model.
/// Inputs are represented as PassthroughSubject publishers that can be triggered from the view.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol CitiesViewModelInput {
    /// Subject for triggering cities loading.
    var loadCitiesSubject: PassthroughSubject<Void, Never> { get }
    
    /// Subject for deleting a city at specific indices.
    var deleteCitySubject: PassthroughSubject<IndexSet, Never> { get }
    
    /// Subject for retrying after an error.
    var retrySubject: PassthroughSubject<Void, Never> { get }
}

/// Protocol defining output state for the cities view model.
///
/// **Specification Interpretation:**
/// This protocol defines all state and data that the view model publishes.
/// Outputs are represented as AnyPublisher publishers that the view can observe.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol CitiesViewModelOutput {
    /// Publisher for the list of cities.
    var cities: AnyPublisher<[City], Never> { get }
    
    /// Publisher indicating if cities are currently being loaded.
    var isLoading: AnyPublisher<Bool, Never> { get }
    
    /// Publisher for error messages.
    var errorMessage: AnyPublisher<String?, Never> { get }
    
    /// Publisher indicating if the cities list is empty.
    var isEmpty: AnyPublisher<Bool, Never> { get }
}

/// Combined protocol for the cities view model.
///
/// **Specification Interpretation:**
/// This typealias combines both input and output protocols, providing a complete
/// interface for the view model that supports both actions and state observation.
///
/// **Access Control:**
/// - Internal typealias: Used within the presentation layer
typealias CitiesViewModelProtocol = CitiesViewModelInput & CitiesViewModelOutput

// MARK: - View Model Implementation

/// View model for the cities list view.
///
/// **Specification Interpretation:**
/// This view model manages the state and business logic for displaying and managing
/// a list of saved cities. It handles loading cities from storage, deleting cities,
/// and error management. It follows the input/output protocol pattern for better
/// testability and separation of concerns.
///
/// **Access Control:**
/// - Internal class: Used within the module
/// - ObservableObject: Enables SwiftUI binding
/// - Final class: Prevents inheritance for better performance
/// - MainActor: Ensures all operations run on the main thread
@MainActor
final class CitiesViewModel: ObservableObject, CitiesViewModelProtocol {
    
    // MARK: - Input Subjects
    
    /// Subject for triggering cities loading.
    let loadCitiesSubject = PassthroughSubject<Void, Never>()
    
    /// Subject for deleting a city at specific indices.
    let deleteCitySubject = PassthroughSubject<IndexSet, Never>()
    
    /// Subject for retrying after an error.
    let retrySubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Output Publishers
    
    /// Published property for the list of cities.
    @Published private var citiesValue: [City] = []
    
    /// Publisher for the list of cities.
    var cities: AnyPublisher<[City], Never> {
        $citiesValue.eraseToAnyPublisher()
    }
    
    /// Published property indicating if cities are being loaded.
    @Published private var isLoadingValue: Bool = false
    
    /// Publisher indicating if cities are currently being loaded.
    var isLoading: AnyPublisher<Bool, Never> {
        $isLoadingValue.eraseToAnyPublisher()
    }
    
    /// Published property for error messages.
    @Published private var errorMessageValue: String?
    
    /// Publisher for error messages.
    var errorMessage: AnyPublisher<String?, Never> {
        $errorMessageValue.eraseToAnyPublisher()
    }
    
    /// Publisher indicating if the cities list is empty.
    var isEmpty: AnyPublisher<Bool, Never> {
        $citiesValue
            .map { $0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    // MARK: - SwiftUI Convenience Properties
    
    /// Convenience property for SwiftUI binding - cities list.
    ///
    /// **Specification:** Provides direct access to the cities list for SwiftUI views.
    var citiesList: [City] {
        citiesValue
    }
    
    /// Convenience property for SwiftUI binding - loading state.
    var isLoadingState: Bool {
        isLoadingValue
    }
    
    /// Convenience property for SwiftUI binding - error message.
    var errorMessageText: String? {
        errorMessageValue
    }
    
    // MARK: - Private Properties
    
    /// Use case for fetching cities from storage.
    private let fetchUseCase: FetchCitiesUseCase
    
    /// Use case for deleting a city from storage.
    private let deleteUseCase: DeleteCityUseCase
    
    /// Cancellables for managing Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with required use cases.
    ///
    /// **Specification:** Sets up Combine subscriptions for input subjects and
    /// automatically triggers initial cities loading.
    ///
    /// - Parameters:
    ///   - fetchUseCase: Use case for fetching cities
    ///   - deleteUseCase: Use case for deleting cities
    init(
        fetchUseCase: FetchCitiesUseCase,
        deleteUseCase: DeleteCityUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        
        setupBindings()
        
        // Automatically load cities on initialization
        loadCitiesSubject.send()
    }
    
    // MARK: - Private Methods
    
    /// Sets up Combine bindings for input subjects.
    ///
    /// **Specification:** Subscribes to input subjects and triggers appropriate actions
    /// when events are received.
    private func setupBindings() {
        // Handle load cities requests
        loadCitiesSubject
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.fetchSavedCities()
                }
            }
            .store(in: &cancellables)
        
        // Handle delete city requests
        deleteCitySubject
            .sink { [weak self] indexSet in
                Task { @MainActor [weak self] in
                    await self?.deleteCity(at: indexSet)
                }
            }
            .store(in: &cancellables)
        
        // Handle retry requests
        retrySubject
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.fetchSavedCities()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Fetches saved cities from storage.
    ///
    /// **Specification:** Loads all saved cities from local storage and updates
    /// the cities list. Handles loading states and errors.
    private func fetchSavedCities() async {
        isLoadingValue = true
        errorMessageValue = nil
        defer { isLoadingValue = false }
        
        do {
            citiesValue = try await fetchUseCase.execute()
        } catch {
            errorMessageValue = error.localizedDescription
        }
    }
    
    /// Deletes cities at the specified indices.
    ///
    /// **Specification:** Deletes cities from storage and refreshes the list.
    /// Handles errors during deletion.
    ///
    /// - Parameter indexSet: The indices of cities to delete
    private func deleteCity(at indexSet: IndexSet) async {
        let citiesToRemove = indexSet.compactMap { citiesValue[safe: $0] }
        
        guard !citiesToRemove.isEmpty else { return }
        
        do {
            for city in citiesToRemove {
                try await deleteUseCase.execute(city: city)
            }
            await fetchSavedCities()
        } catch {
            errorMessageValue = error.localizedDescription
        }
    }
}

// MARK: - Collection Extension

/// Extension for safe array subscripting.
///
/// **Access Control:**
/// - Private extension: Used only within CitiesViewModel
private extension Collection {
    /// Safely accesses an element at the given index.
    ///
    /// - Parameter index: The index to access
    /// - Returns: The element at the index, or nil if out of bounds
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
