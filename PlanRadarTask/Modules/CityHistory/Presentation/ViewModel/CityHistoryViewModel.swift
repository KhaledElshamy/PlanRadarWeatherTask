//
//  CityHistoryViewModel.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import Combine

// MARK: - View Model Protocols

/// Protocol defining input actions for the city history view model.
///
/// **Specification Interpretation:**
/// This protocol defines all user actions and triggers that can be sent to the view model.
/// Inputs are represented as PassthroughSubject publishers that can be triggered from the view.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol CityHistoryViewModelInput {
    /// Subject for triggering history loading.
    var loadHistorySubject: PassthroughSubject<Void, Never> { get }
    
    /// Subject for retrying after an error.
    var retrySubject: PassthroughSubject<Void, Never> { get }
    
    /// Subject for selecting a history entry to view details.
    var selectEntrySubject: PassthroughSubject<CityHistoryEntry, Never> { get }
}

/// Protocol defining output state for the city history view model.
///
/// **Specification Interpretation:**
/// This protocol defines all state and data that the view model publishes.
/// Outputs are represented as AnyPublisher publishers that the view can observe.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol CityHistoryViewModelOutput {
    /// Publisher for the list of history entries.
    var historyEntries: AnyPublisher<[CityHistoryEntry], Never> { get }
    
    /// Publisher indicating if history is currently being loaded.
    var isLoading: AnyPublisher<Bool, Never> { get }
    
    /// Publisher for error messages.
    var errorMessage: AnyPublisher<String?, Never> { get }
    
    /// Publisher indicating if the history list is empty.
    var isEmpty: AnyPublisher<Bool, Never> { get }
    
    /// Publisher for the city name.
    var cityName: AnyPublisher<String, Never> { get }
}

/// Combined protocol for the city history view model.
///
/// **Specification Interpretation:**
/// This typealias combines both input and output protocols, providing a complete
/// interface for the view model that supports both actions and state observation.
///
/// **Access Control:**
/// - Internal typealias: Used within the presentation layer
typealias CityHistoryViewModelProtocol = CityHistoryViewModelInput & CityHistoryViewModelOutput

// MARK: - View Model Implementation

/// View model for the city history view.
///
/// **Specification Interpretation:**
/// This view model manages the state and business logic for displaying historical
/// weather data for a city. It handles loading history entries, error management,
/// and entry selection. It follows the input/output protocol pattern for better
/// testability and separation of concerns.
///
/// **Access Control:**
/// - Internal class: Used within the module
/// - ObservableObject: Enables SwiftUI binding
/// - Final class: Prevents inheritance for better performance
/// - MainActor: Ensures all operations run on the main thread
@MainActor
final class CityHistoryViewModel: ObservableObject, CityHistoryViewModelProtocol {
    
    // MARK: - Input Subjects
    
    /// Subject for triggering history loading.
    let loadHistorySubject = PassthroughSubject<Void, Never>()
    
    /// Subject for retrying after an error.
    let retrySubject = PassthroughSubject<Void, Never>()
    
    /// Subject for selecting a history entry to view details.
    let selectEntrySubject = PassthroughSubject<CityHistoryEntry, Never>()
    
    // MARK: - Output Publishers
    
    /// Published property for the list of history entries.
    @Published private var historyEntriesValue: [CityHistoryEntry] = []
    
    /// Publisher for the list of history entries.
    var historyEntries: AnyPublisher<[CityHistoryEntry], Never> {
        $historyEntriesValue.eraseToAnyPublisher()
    }
    
    /// Published property indicating if history is being loaded.
    @Published private var isLoadingValue: Bool = false
    
    /// Publisher indicating if history is currently being loaded.
    var isLoading: AnyPublisher<Bool, Never> {
        $isLoadingValue.eraseToAnyPublisher()
    }
    
    /// Published property for error messages.
    @Published private var errorMessageValue: String?
    
    /// Publisher for error messages.
    var errorMessage: AnyPublisher<String?, Never> {
        $errorMessageValue.eraseToAnyPublisher()
    }
    
    /// Publisher indicating if the history list is empty.
    var isEmpty: AnyPublisher<Bool, Never> {
        $historyEntriesValue
            .map { $0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for the city name.
    var cityName: AnyPublisher<String, Never> {
        Just(cityNameValue)
            .eraseToAnyPublisher()
    }
    
    // MARK: - SwiftUI Convenience Properties
    
    /// Convenience property for SwiftUI binding - history entries list.
    var historyEntriesList: [CityHistoryEntry] {
        historyEntriesValue
    }
    
    /// Convenience property for SwiftUI binding - loading state.
    var isLoadingState: Bool {
        isLoadingValue
    }
    
    /// Convenience property for SwiftUI binding - error message.
    var errorMessageText: String? {
        errorMessageValue
    }
    
    /// Convenience property for SwiftUI binding - city name.
    let cityNameValue: String
    
    // MARK: - Private Properties
    
    /// Use case for fetching city history.
    private let fetchHistoryUseCase: FetchCityHistoryUseCase
    
    /// Cancellables for managing Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with a city name and use case.
    ///
    /// **Specification:** Sets up Combine subscriptions for input subjects and
    /// automatically triggers initial history loading.
    ///
    /// - Parameters:
    ///   - cityName: The name of the city to fetch history for
    ///   - fetchHistoryUseCase: Use case for fetching city history
    init(
        cityName: String,
        fetchHistoryUseCase: FetchCityHistoryUseCase
    ) {
        self.cityNameValue = cityName
        self.fetchHistoryUseCase = fetchHistoryUseCase
        
        setupBindings()
        
        // Automatically load history on initialization
        loadHistorySubject.send()
    }
    
    // MARK: - Private Methods
    
    /// Sets up Combine bindings for input subjects.
    ///
    /// **Specification:** Subscribes to input subjects and triggers appropriate actions
    /// when events are received.
    private func setupBindings() {
        // Handle load history requests
        loadHistorySubject
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.fetchHistory()
                }
            }
            .store(in: &cancellables)
        
        // Handle retry requests
        retrySubject
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.fetchHistory()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Fetches historical entries from storage.
    ///
    /// **Specification:** Loads all historical weather entries for the city and updates
    /// the history list. Handles loading states and errors.
    private func fetchHistory() async {
        isLoadingValue = true
        errorMessageValue = nil
        defer { isLoadingValue = false }
        
        do {
            historyEntriesValue = try await fetchHistoryUseCase.execute(cityName: cityNameValue)
        } catch {
            errorMessageValue = error.localizedDescription
        }
    }
}

