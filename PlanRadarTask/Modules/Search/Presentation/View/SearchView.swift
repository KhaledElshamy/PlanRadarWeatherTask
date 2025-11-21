import SwiftUI

struct SearchView: View {

    @ObservedObject var viewModel: SearchViewModel
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                description
                searchField
                if let result = viewModel.latestResult {
                    Text("Saved \(result.city.displayName)")
                        .foregroundColor(.pink)
                        .font(.callout)
                        .padding(.horizontal)
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()

            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Add City")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.pink)
        }
    }

    private var description: some View {
        Text("Enter city, postcode or airport location")
            .foregroundColor(.white.opacity(0.8))
            .font(.callout)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            TextField("Search", text: $viewModel.query, onCommit: viewModel.submit)
                .foregroundColor(.white)
            Button("Search") {
                viewModel.submit()
            }
            .foregroundColor(.pink)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(14)
    }

    private enum Colors {
        static let background = LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.09)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

