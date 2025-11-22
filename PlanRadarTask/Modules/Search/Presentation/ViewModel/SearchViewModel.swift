//
//  SearchViewModel.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import Combine

// MARK: - View Model Protocols

/// Protocol defining input actions for the search view model.
///
/// **Specification Interpretation:**
/// This protocol defines all user actions and triggers that can be sent to the view model.
/// Inputs are represented as PassthroughSubject publishers that can be triggered from the view.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol SearchViewModelInput {
    /// Subject for updating the search query text.
    var querySubject: PassthroughSubject<String, Never> { get }
    
    /// Subject for submitting the search query.
    var submitSubject: PassthroughSubject<Void, Never> { get }
    
    /// Subject for retrying after an error.
    var retrySubject: PassthroughSubject<Void, Never> { get }
    
    /// Subject for clearing the search query.
    var clearQuerySubject: PassthroughSubject<Void, Never> { get }
}

/// Protocol defining output state for the search view model.
///
/// **Specification Interpretation:**
/// This protocol defines all state and data that the view model publishes.
/// Outputs are represented as AnyPublisher publishers that the view can observe.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol SearchViewModelOutput {
    /// Publisher for the search query text.
    var query: AnyPublisher<String, Never> { get }
    
    /// Publisher indicating if the search is currently being performed.
    var isLoading: AnyPublisher<Bool, Never> { get }
    
    /// Publisher for error messages.
    var errorMessage: AnyPublisher<String?, Never> { get }
    
    /// Publisher for the latest search result.
    var latestResult: AnyPublisher<SearchResult?, Never> { get }
    
    /// Publisher indicating if the query is empty.
    var isQueryEmpty: AnyPublisher<Bool, Never> { get }
    
    /// Publisher indicating if the submit button should be enabled.
    var canSubmit: AnyPublisher<Bool, Never> { get }
}

/// Combined protocol for the search view model.
///
/// **Specification Interpretation:**
/// This typealias combines both input and output protocols, providing a complete
/// interface for the view model that supports both actions and state observation.
///
/// **Access Control:**
/// - Internal typealias: Used within the presentation layer
typealias SearchViewModelProtocol = SearchViewModelInput & SearchViewModelOutput

// MARK: - View Model Implementation

/// View model for the search view.
///
/// **Specification Interpretation:**
/// This view model manages the state and business logic for searching cities and
/// adding them to local storage. It handles search queries, API calls, error management,
/// and completion callbacks. It follows the input/output protocol pattern for better
/// testability and separation of concerns.
///
/// **Access Control:**
/// - Internal class: Used within the module
/// - ObservableObject: Enables SwiftUI binding
/// - Final class: Prevents inheritance for better performance
/// - MainActor: Ensures all operations run on the main thread
@MainActor
final class SearchViewModel: ObservableObject, SearchViewModelProtocol {
    
    // MARK: - Input Subjects
    
    /// Subject for updating the search query text.
    let querySubject = PassthroughSubject<String, Never>()
    
    /// Subject for submitting the search query.
    let submitSubject = PassthroughSubject<Void, Never>()
    
    /// Subject for retrying after an error.
    let retrySubject = PassthroughSubject<Void, Never>()
    
    /// Subject for clearing the search query.
    let clearQuerySubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Output Publishers
    
    /// Published property for the search query text.
    @Published private var queryValue: String = ""
    
    /// Publisher for the search query text.
    var query: AnyPublisher<String, Never> {
        $queryValue.eraseToAnyPublisher()
    }
    
    /// Published property indicating if the search is being performed.
    @Published private var isLoadingValue: Bool = false
    
    /// Publisher indicating if the search is currently being performed.
    var isLoading: AnyPublisher<Bool, Never> {
        $isLoadingValue.eraseToAnyPublisher()
    }
    
    /// Published property for error messages.
    @Published private var errorMessageValue: String?
    
    /// Publisher for error messages.
    var errorMessage: AnyPublisher<String?, Never> {
        $errorMessageValue.eraseToAnyPublisher()
    }
    
    /// Published property for the latest search result.
    @Published private var latestResultValue: SearchResult?
    
    /// Publisher for the latest search result.
    var latestResult: AnyPublisher<SearchResult?, Never> {
        $latestResultValue.eraseToAnyPublisher()
    }
    
    /// Publisher indicating if the query is empty.
    var isQueryEmpty: AnyPublisher<Bool, Never> {
        $queryValue
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .eraseToAnyPublisher()
    }
    
    /// Publisher indicating if the submit button should be enabled.
    var canSubmit: AnyPublisher<Bool, Never> {
        $queryValue
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .eraseToAnyPublisher()
    }
    
    // MARK: - SwiftUI Convenience Properties
    
    /// Convenience property for SwiftUI binding - search query.
    ///
    /// **Specification:** Provides direct access to the query text for SwiftUI views.
    var queryText: String {
        get { queryValue }
        set { queryValue = newValue }
    }
    
    /// Convenience property for SwiftUI binding - loading state.
    var isLoadingState: Bool {
        isLoadingValue
    }
    
    /// Convenience property for SwiftUI binding - error message.
    var errorMessageText: String? {
        errorMessageValue
    }
    
    /// Convenience property for SwiftUI binding - latest result.
    var latestSearchResult: SearchResult? {
        latestResultValue
    }
    
    // MARK: - Private Properties
    
    /// Use case for searching cities via API.
    private let searchUseCase: SearchCityUseCaseProtocol
    
    /// Use case for adding a city to local storage.
    private let addUseCase: AddCityUseCaseProtocol
    
    /// Completion callback to be called after successful search and add.
    private let completion: () -> Void
    
    /// Cancellables for managing Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with required use cases and completion callback.
    ///
    /// **Specification:** Sets up Combine subscriptions for input subjects.
    ///
    /// - Parameters:
    ///   - searchUseCase: Use case for searching cities
    ///   - addUseCase: Use case for adding cities to storage
    ///   - completion: Completion callback called after successful search and add
    init(
        searchUseCase: SearchCityUseCaseProtocol,
        addUseCase: AddCityUseCaseProtocol,
        completion: @escaping () -> Void
    ) {
        self.searchUseCase = searchUseCase
        self.addUseCase = addUseCase
        self.completion = completion
        
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    /// Sets up Combine bindings for input subjects.
    ///
    /// **Specification:** Subscribes to input subjects and triggers appropriate actions
    /// when events are received.
    private func setupBindings() {
        // Handle query updates
        querySubject
            .sink { [weak self] query in
                self?.queryValue = query
            }
            .store(in: &cancellables)
        
        // Handle submit requests
        submitSubject
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)
        
        // Handle retry requests
        retrySubject
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)
        
        // Handle clear query requests
        clearQuerySubject
            .sink { [weak self] _ in
                self?.queryValue = ""
                self?.errorMessageValue = nil
                self?.latestResultValue = nil
            }
            .store(in: &cancellables)
    }
    
    /// Performs the search operation.
    ///
    /// **Specification:** Validates the query, searches for the city via API,
    /// adds it to local storage, and calls the completion callback on success.
    /// Handles loading states and errors.
    private func performSearch() async {
        let trimmed = queryValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            errorMessageValue = "Please enter a valid location."
            return
        }
        
        isLoadingValue = true
        errorMessageValue = nil
        latestResultValue = nil
        
        defer { isLoadingValue = false }
        
        do {
            let city = try await searchUseCase.execute(query: trimmed)
            try await addUseCase.execute(city: city)
            latestResultValue = SearchResult(city: city)
            completion()
        } catch {
            errorMessageValue = error.localizedDescription
        }
    }
}
