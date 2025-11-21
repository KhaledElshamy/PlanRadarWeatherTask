import SwiftUI
import Combine

final class AppFlowCoordinator: ObservableObject {

    private let citiesCoordinator: CitiesFlowCoordinator

    init(appDIContainer: AppDIContainer = AppDIContainer()) {
        self.citiesCoordinator = CitiesFlowCoordinator(
            fetchCities: appDIContainer.fetchCitiesUseCase,
            deleteCity: appDIContainer.deleteCityUseCase,
            searchCoordinator: appDIContainer.searchFlowCoordinator
        )
    }

    @ViewBuilder
    var rootView: some View {
        citiesCoordinator.makeCitiesView()
    }
}

