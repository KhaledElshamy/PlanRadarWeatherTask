//
//  CitiesView.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI
import Combine

struct CitiesView: View {
    
    @ObservedObject var viewModel: CitiesViewModel
    @ObservedObject var coordinator: CitiesFlowCoordinator
    
    @State private var cities: [City] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
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

                if let message = errorMessage {
                    ErrorBanner(message: message)
                        .transition(.move(edge: .top))
                }

                if isLoading {
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
            .sheet(item: $coordinator.selectedCity) { city in
                coordinator.cityDetailsView(for: city)
                    .presentationDetents([.fraction(1.0)])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(false)
            }
            .onReceive(viewModel.cities) { cities in
                self.cities = cities
            }
            .onReceive(viewModel.isLoading) { loading in
                self.isLoading = loading
            }
            .onReceive(viewModel.errorMessage) { message in
                self.errorMessage = message
            }
            .onAppear {
                viewModel.loadCitiesSubject.send()
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
            if cities.isEmpty, !isLoading {
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
            ForEach(cities) { city in
                Button(action: {
                    coordinator.showCityDetails(for: city)
                }) {
                    CityRow(city: city)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                viewModel.deleteCitySubject.send(indexSet)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct CityRow: View {
    let city: City

    var body: some View {
        HStack {
            Text(city.displayName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
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

//#Preview {
//    let container = AppDIContainer()
//    let coordinator = CitiesFlowCoordinator(
//        fetchCities: container.fetchCitiesUseCase,
//        deleteCity: container.deleteCityUseCase,
//        searchCoordinator: container.searchFlowCoordinator
//    )
//    CitiesView(viewModel: coordinator.viewModel, coordinator: coordinator)
//}
