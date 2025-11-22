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
    @Environment(\.colorScheme) private var colorScheme
    
    /// The city being displayed (for sheet presentation)
    let city: City
    
    private var colors: AppColors {
        AppColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
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
                        .fill(colors.buttonAccent)
                        .frame(width: 40, height: 40)
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            Spacer()
            
            Text(viewModel.cityNameValue.uppercased())
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colors.headerText)
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
        .background(colors.cardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Footer
    
    /// Footer section with update information.
    private var footer: some View {
        VStack(spacing: 8) {
            Text("WEATHER INFORMATION FOR \(viewModel.cityNameValue.uppercased()) RECEIVED ON")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Text(viewModel.formattedUpdateTimeValue)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(colors.secondaryText)
        }
        .padding(.top, 32)
    }
}

// MARK: - Weather Icon View

/// View component for displaying the weather icon with loading and error states.
///
/// **Access Control:**
/// - Private struct: Used only within CityDetailsView
private struct WeatherIconView: View {
    @ObservedObject var viewModel: CityDetailsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var iconImage: Image?
    @State private var isLoading: Bool = false
    
    private var colors: AppColors {
        AppColors(colorScheme: colorScheme)
    }
    
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
                    .foregroundColor(colors.buttonAccent)
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
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AppColors {
        AppColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colors.buttonAccent)
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

