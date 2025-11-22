//
//  CityHistoryFlowCoordinator.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI
import Combine

/// Flow coordinator for the City History module navigation.
///
/// **Specification Interpretation:**
/// This coordinator manages navigation within the City History module, handling
/// the presentation of historical weather data and detail views.
///
/// **Access Control:**
/// - Internal class: Used within the module
/// - ObservableObject: Enables SwiftUI state management
final class CityHistoryFlowCoordinator: ObservableObject {
    
    /// Use case for fetching city history.
    private let fetchHistoryUseCase: FetchCityHistoryUseCase
    
    /// Initializes the coordinator with required dependencies.
    ///
    /// - Parameter fetchHistoryUseCase: Use case for fetching city history
    init(fetchHistoryUseCase: FetchCityHistoryUseCase) {
        self.fetchHistoryUseCase = fetchHistoryUseCase
    }
    
    /// Creates the city history view.
    ///
    /// - Parameter cityName: The name of the city to display history for
    /// - Returns: The city history view
    @ViewBuilder
    func makeHistoryView(cityName: String) -> some View {
        let viewModel = CityHistoryViewModel(
            cityName: cityName,
            fetchHistoryUseCase: fetchHistoryUseCase
        )
        CityHistoryView(viewModel: viewModel)
    }
}

