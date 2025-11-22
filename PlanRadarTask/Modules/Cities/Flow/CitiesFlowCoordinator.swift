//
//  CitiesFlowCoordinator.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI
import Combine

/// Flow coordinator for the Cities module navigation.
///
/// **Specification Interpretation:**
/// This coordinator manages navigation within the Cities module, handling transitions
/// between the cities list, search view, and city details view. It maintains the
/// navigation state and provides view builders for each route.
///
/// **Access Control:**
/// - Internal class: Used within the module
/// - ObservableObject: Enables SwiftUI state management
final class CitiesFlowCoordinator: ObservableObject {
    
    /// Navigation routes within the Cities module.
    enum Route: Hashable {
        case search
    }
    
    /// Current navigation path
    @Published var path: [Route] = []
    
    /// Selected city for bottom sheet presentation
    @Published var selectedCity: City?
    
    /// View model for the cities list
    let viewModel: CitiesViewModel
    
    /// Search flow coordinator dependency
    private let searchCoordinator: SearchFlowCoordinator
    
    /// Use case for fetching weather icons
    private let fetchWeatherIconUseCase: FetchWeatherIconUseCase
    
    /// Initializes the coordinator with required dependencies.
    ///
    /// - Parameters:
    ///   - fetchCities: Use case for fetching cities
    ///   - deleteCity: Use case for deleting cities
    ///   - searchCoordinator: Coordinator for search flow
    ///   - fetchWeatherIconUseCase: Use case for fetching weather icons
    init(
        fetchCities: FetchCitiesUseCase,
        deleteCity: DeleteCityUseCase,
        searchCoordinator: SearchFlowCoordinator,
        fetchWeatherIconUseCase: FetchWeatherIconUseCase
    ) {
        self.viewModel = CitiesViewModel(fetchUseCase: fetchCities, deleteUseCase: deleteCity)
        self.searchCoordinator = searchCoordinator
        self.fetchWeatherIconUseCase = fetchWeatherIconUseCase
    }
    
    /// Creates the main cities view.
    ///
    /// - Returns: The cities list view
    @ViewBuilder
    func makeCitiesView() -> some View {
        CitiesView(viewModel: viewModel, coordinator: self)
    }
    
    /// Navigates to the search view.
    func showSearch() {
        path.append(.search)
    }
    
    /// Presents the city details view as a bottom sheet.
    ///
    /// - Parameter city: The city to display details for
    func showCityDetails(for city: City) {
        selectedCity = city
    }
    
    /// Dismisses the city details bottom sheet.
    func dismissCityDetails() {
        selectedCity = nil
    }
    
    /// Pops the search view from navigation.
    func popSearch() {
        path.removeAll { $0 == .search }
    }
    
    /// Creates the search view.
    ///
    /// - Returns: The search view
    func searchView() -> some View {
        let success: () -> Void = { [weak self] in
            self?.viewModel.loadCitiesSubject.send()
            self?.popSearch()
        }
        let cancel: () -> Void = { [weak self] in
            self?.popSearch()
        }
        return searchCoordinator.makeSearchView(onSearchSuccess: success, onCancel: cancel)
    }
    
    /// Creates the city details view.
    ///
    /// - Parameter city: The city to display
    /// - Returns: The city details view
    @ViewBuilder
    func cityDetailsView(for city: City) -> some View {
        CityDetailsView(
            viewModel: CityDetailsViewModel(city: city, fetchWeatherIconUseCase: fetchWeatherIconUseCase),
            city: city
        )
    }
}

