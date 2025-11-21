//
//  CitiesView.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI

struct CitiesView: View {
    
    @ObservedObject var viewModel: CitiesViewModel
    @ObservedObject var coordinator: CitiesFlowCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    header
                    content
                }
                .padding()

                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message)
                        .transition(.move(edge: .top))
                }

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(1.3)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: CitiesFlowCoordinator.Route.self) { route in
                switch route {
                case .search:
                    coordinator.searchView()
                }
            }
            .onAppear {
                viewModel.loadCities()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("CITIES")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .kerning(2)

            Spacer()

            Button(action: coordinator.showSearch) {
                ZStack {
                    Circle()
                        .fill(Colors.accent)
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
    }

    private var content: some View {
        Group {
            if viewModel.cities.isEmpty, !viewModel.isLoading {
                placeholder
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholder: some View {
        Text("Start adding cities by tapping the plus button.")
            .foregroundColor(.gray.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }

    private var list: some View {
        List {
            ForEach(viewModel.cities) { city in
                CityRow(city: city)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: viewModel.deleteCity)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct CityRow: View {
    let city: City

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(city.displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(city.temperature)
                    .font(.title3)
                    .foregroundColor(.pink)
            }

            HStack(spacing: 10) {
                Label(city.description, systemImage: "cloud.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
                Spacer()
                Text(city.wind)
                    .foregroundColor(.gray)
                    .font(.caption2)
            }

            HStack {
                Text("Humidity \(city.humidity)")
                    .foregroundColor(.gray)
                    .font(.caption2)
                Spacer()
                Text("Updated \(city.updatedAt.formatted(.dateTime.hour().minute()))")
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
        }
        .padding()
        .background(.black.opacity(0.4))
        .cornerRadius(20)
    }
}

private extension CitiesView {
    enum Colors {
        static let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.03, green: 0.03, blue: 0.05),
                Color(red: 0.01, green: 0.01, blue: 0.03)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        static let accent = Color(red: 1, green: 0.27, blue: 0.41)
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        VStack {
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.9))
                .cornerRadius(12)
        }
        .padding(.top, 60)
    }
}

#Preview {
    let container = AppDIContainer()
    let coordinator = CitiesFlowCoordinator(
        fetchCities: container.fetchCitiesUseCase,
        deleteCity: container.deleteCityUseCase,
        searchCoordinator: container.searchFlowCoordinator
    )
    CitiesView(viewModel: coordinator.viewModel, coordinator: coordinator)
}
