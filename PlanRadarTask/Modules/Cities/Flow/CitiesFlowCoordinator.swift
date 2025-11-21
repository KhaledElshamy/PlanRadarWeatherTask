import SwiftUI
import Combine

final class CitiesFlowCoordinator: ObservableObject {
    
    enum Route: Hashable {
        case search
    }
    
    @Published var path: [Route] = []
    
    let viewModel: CitiesViewModel
    private let searchCoordinator: SearchFlowCoordinator
    
    init(
        fetchCities: FetchCitiesUseCase,
        deleteCity: DeleteCityUseCase,
        searchCoordinator: SearchFlowCoordinator
    ) {
        self.viewModel = CitiesViewModel(fetchUseCase: fetchCities, deleteUseCase: deleteCity)
        self.searchCoordinator = searchCoordinator
    }
    
    @ViewBuilder
    func makeCitiesView() -> some View {
        CitiesView(viewModel: viewModel, coordinator: self)
    }
    
    func showSearch() {
        path.append(.search)
    }
    
    func popSearch() {
        path.removeAll { $0 == .search }
    }
    
    func searchView() -> some View {
        let success: () -> Void = { [weak self] in
            self?.viewModel.loadCities()
            self?.popSearch()
        }
        let cancel: () -> Void = { [weak self] in
            self?.popSearch()
        }
        return searchCoordinator.makeSearchView(onSearchSuccess: success, onCancel: cancel)
    }
}

