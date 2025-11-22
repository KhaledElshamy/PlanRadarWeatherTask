//
//  AppFlowCoordinator.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI
import Combine

/// The main application flow coordinator, responsible for setting up the initial view and coordinating with module-specific flows.
///
/// **Specification Interpretation:**
/// This coordinator serves as the root coordinator for the entire application. It initializes
/// module-specific coordinators and provides the root view for the app's navigation hierarchy.
///
/// **Access Control:**
/// - Internal class: Used within the application module
/// - ObservableObject: Enables SwiftUI state management
final class AppFlowCoordinator: ObservableObject {

    private let citiesCoordinator: CitiesFlowCoordinator

    /// Initializes the AppFlowCoordinator with an optional AppDIContainer.
    ///
    /// - Parameter appDIContainer: The dependency injection container for the app. Defaults to a new instance.
    init(appDIContainer: AppDIContainer = AppDIContainer()) {
        self.citiesCoordinator = CitiesFlowCoordinator(
            fetchCities: appDIContainer.fetchCitiesUseCase,
            deleteCity: appDIContainer.deleteCityUseCase,
            searchCoordinator: appDIContainer.searchFlowCoordinator,
            fetchWeatherIconUseCase: appDIContainer.fetchWeatherIconUseCase,
            historyCoordinator: appDIContainer.cityHistoryFlowCoordinator
        )
    }

    @ViewBuilder
    var rootView: some View {
        citiesCoordinator.makeCitiesView()
    }
}

