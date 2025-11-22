//
//  CityDetailsView.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import SwiftUI

/// View displaying detailed weather information for a selected city.
///
/// **Specification Interpretation:**
/// This view presents comprehensive weather details in a card-based layout matching
/// the design specification. It displays the weather icon, description, temperature,
/// humidity, and wind speed with a clear visual hierarchy.
///
/// **Access Control:**
/// - Internal struct: Used within the module
/// - Public View conformance: SwiftUI requirement
struct CityDetailsView: View {
    
    @ObservedObject var viewModel: CityDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// The city being displayed (for sheet presentation)
    let city: City
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                Spacer()
                weatherCard
                Spacer()
                footer
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    
    /// Header section with back button and city name.
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.accent)
                        .frame(width: 40, height: 40)
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            Spacer()
            
            Text(viewModel.cityNameValue.uppercased())
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
                .kerning(1.5)
            
            Spacer()
            
            // Invisible spacer to center the title
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Weather Card
    
    /// Main weather information card.
    private var weatherCard: some View {
        VStack(spacing: 32) {
            // Weather Icon
            WeatherIconView(viewModel: viewModel)
            
            // Weather Details
            VStack(spacing: 20) {
                WeatherDetailRow(label: "DESCRIPTION", value: viewModel.descriptionValue)
                WeatherDetailRow(label: "TEMPERATURE", value: viewModel.temperatureValue)
                WeatherDetailRow(label: "HUMIDITY", value: viewModel.humidityValue)
                WeatherDetailRow(label: "WINDSPEED", value: viewModel.windSpeedValue)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Colors.cardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Footer
    
    /// Footer section with update information.
    private var footer: some View {
        VStack(spacing: 8) {
            Text("WEATHER INFORMATION FOR \(viewModel.cityNameValue.uppercased()) RECEIVED ON")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text(viewModel.formattedUpdateTimeValue)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Colors
    
    private enum Colors {
        static let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.03, green: 0.03, blue: 0.05),
                Color(red: 0.01, green: 0.01, blue: 0.03)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.17)
        static let accent = Color(red: 1, green: 0.27, blue: 0.41)
    }
}

// MARK: - Weather Icon View

/// View component for displaying the weather icon with loading and error states.
///
/// **Access Control:**
/// - Private struct: Used only within CityDetailsView
private struct WeatherIconView: View {
    @ObservedObject var viewModel: CityDetailsViewModel
    @State private var iconImage: Image?
    @State private var isLoading: Bool = false
    
    var body: some View {
        Group {
            if let iconImage = iconImage {
                iconImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            } else if isLoading {
                ProgressView()
                    .frame(width: 120, height: 120)
            } else {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 1, green: 0.27, blue: 0.41))
            }
        }
        .onReceive(viewModel.weatherIconImage) { image in
            self.iconImage = image
        }
        .onReceive(viewModel.isLoadingIcon) { loading in
            self.isLoading = loading
        }
    }
}

// MARK: - Weather Detail Row

/// Individual weather detail row component.
///
/// **Access Control:**
/// - Private struct: Used only within CityDetailsView
private struct WeatherDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 1, green: 0.27, blue: 0.41))
        }
    }
}

#Preview {
    let container = AppDIContainer()
    let city = City(
        id: "London, GB",
        displayName: "London, GB",
        temperature: "20° C",
        humidity: "45%",
        wind: "20 km/h",
        description: "Cloudy",
        iconURL: URL(string: "https://openweathermap.org/img/w/01d.png"),
        updatedAt: Date()
    )
    CityDetailsView(
        viewModel: CityDetailsViewModel(city: city, fetchWeatherIconUseCase: container.fetchWeatherIconUseCase),
        city: city
    )
}

