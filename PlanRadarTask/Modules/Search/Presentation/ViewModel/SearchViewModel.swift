import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    @Published var query: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var latestResult: SearchResult?

    private let searchUseCase: SearchCityUseCase
    private let addUseCase: AddCityUseCase
    private let completion: () -> Void

    init(
        searchUseCase: SearchCityUseCase,
        addUseCase: AddCityUseCase,
        completion: @escaping () -> Void
    ) {
        self.searchUseCase = searchUseCase
        self.addUseCase = addUseCase
        self.completion = completion
    }

    func submit() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a valid location."
            return
        }

        isLoading = true
        errorMessage = nil
        latestResult = nil

        Task {
            do {
                let city = try await searchUseCase.execute(query: trimmed)
                try await addUseCase.execute(city: city)
                latestResult = SearchResult(city: city)
                completion()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

