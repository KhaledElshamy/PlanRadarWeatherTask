import SwiftUI

final class SearchFlowCoordinator {

    private let searchUseCase: SearchCityUseCase
    private let addUseCase: AddCityUseCase

    init(searchUseCase: SearchCityUseCase, addUseCase: AddCityUseCase) {
        self.searchUseCase = searchUseCase
        self.addUseCase = addUseCase
    }

    func makeSearchView(
        onSearchSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        let viewModel = SearchViewModel(
            searchUseCase: searchUseCase,
            addUseCase: addUseCase,
            completion: onSearchSuccess
        )
        return SearchView(viewModel: viewModel, onCancel: onCancel)
    }
}

