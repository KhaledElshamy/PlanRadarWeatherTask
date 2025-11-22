//
//  CityDetailsViewModel.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - View Model Protocols

/// Protocol defining input actions for the city details view model.
///
/// **Specification Interpretation:**
/// This protocol defines all user actions and triggers that can be sent to the view model.
/// Inputs are represented as PassthroughSubject publishers that can be triggered from the view.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol CityDetailsViewModelInput {
    /// Subject for triggering weather icon loading.
    var loadWeatherIconSubject: PassthroughSubject<Void, Never> { get }
    
    /// Subject for retrying weather icon loading after an error.
    var retryLoadIconSubject: PassthroughSubject<Void, Never> { get }
}

/// Protocol defining output state for the city details view model.
///
/// **Specification Interpretation:**
/// This protocol defines all state and data that the view model publishes.
/// Outputs are represented as AnyPublisher publishers that the view can observe.
///
/// **Access Control:**
/// - Internal protocol: Used within the presentation layer
protocol CityDetailsViewModelOutput {
    /// Publisher for the weather icon image.
    var weatherIconImage: AnyPublisher<Image?, Never> { get }
    
    /// Publisher indicating if the weather icon is currently being loaded.
    var isLoadingIcon: AnyPublisher<Bool, Never> { get }
    
    /// Publisher for weather icon loading errors.
    var iconError: AnyPublisher<String?, Never> { get }
    
    /// Publisher for the city name (without country code).
    var cityName: AnyPublisher<String, Never> { get }
    
    /// Publisher for the weather description.
    var description: AnyPublisher<String, Never> { get }
    
    /// Publisher for the formatted temperature.
    var temperature: AnyPublisher<String, Never> { get }
    
    /// Publisher for the formatted humidity percentage.
    var humidity: AnyPublisher<String, Never> { get }
    
    /// Publisher for the formatted wind speed.
    var windSpeed: AnyPublisher<String, Never> { get }
    
    /// Publisher for the formatted update time.
    var formattedUpdateTime: AnyPublisher<String, Never> { get }
}

/// Combined protocol for the city details view model.
///
/// **Specification Interpretation:**
/// This typealias combines both input and output protocols, providing a complete
/// interface for the view model that supports both actions and state observation.
///
/// **Access Control:**
/// - Internal typealias: Used within the presentation layer
typealias CityDetailsViewModelProtocol = CityDetailsViewModelInput & CityDetailsViewModelOutput

// MARK: - View Model Implementation

/// View model for the city details view.
///
/// **Specification Interpretation:**
/// This view model prepares city data for display in the details view. It formats
/// the weather information and fetches the weather icon image using the use case pattern.
/// It follows the input/output protocol pattern for better testability and separation of concerns.
///
/// **Access Control:**
/// - Internal class: Used within the module
/// - ObservableObject: Enables SwiftUI binding
/// - Final class: Prevents inheritance for better performance
final class CityDetailsViewModel: ObservableObject, CityDetailsViewModelProtocol {
    
    // MARK: - Input Subjects
    
    /// Subject for triggering weather icon loading.
    let loadWeatherIconSubject = PassthroughSubject<Void, Never>()
    
    /// Subject for retrying weather icon loading after an error.
    let retryLoadIconSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Output Publishers
    
    /// Published property for the weather icon image.
    @Published private var weatherIconImageValue: Image?
    
    /// Publisher for the weather icon image.
    var weatherIconImage: AnyPublisher<Image?, Never> {
        $weatherIconImageValue.eraseToAnyPublisher()
    }
    
    /// Published property indicating if the icon is being loaded.
    @Published private var isLoadingIconValue: Bool = false
    
    /// Publisher indicating if the weather icon is currently being loaded.
    var isLoadingIcon: AnyPublisher<Bool, Never> {
        $isLoadingIconValue.eraseToAnyPublisher()
    }
    
    /// Published property for icon loading errors.
    @Published private var iconErrorValue: String?
    
    /// Publisher for weather icon loading errors.
    var iconError: AnyPublisher<String?, Never> {
        $iconErrorValue.eraseToAnyPublisher()
    }
    
    /// Publisher for the city name (without country code).
    var cityName: AnyPublisher<String, Never> {
        Just(extractCityName(from: city.displayName))
            .eraseToAnyPublisher()
    }
    
    /// Publisher for the weather description.
    var description: AnyPublisher<String, Never> {
        Just(city.description.capitalized)
            .eraseToAnyPublisher()
    }
    
    /// Publisher for the formatted temperature.
    var temperature: AnyPublisher<String, Never> {
        Just(city.temperature)
            .eraseToAnyPublisher()
    }
    
    /// Publisher for the formatted humidity percentage.
    var humidity: AnyPublisher<String, Never> {
        Just(city.humidity)
            .eraseToAnyPublisher()
    }
    
    /// Publisher for the formatted wind speed.
    var windSpeed: AnyPublisher<String, Never> {
        Just(city.wind)
            .eraseToAnyPublisher()
    }
    
    /// Publisher for the formatted update time.
    var formattedUpdateTime: AnyPublisher<String, Never> {
        Just(formatUpdateTime(city.updatedAt))
            .eraseToAnyPublisher()
    }
    
    // MARK: - SwiftUI Convenience Properties
    
    /// Convenience property for SwiftUI binding - city name.
    ///
    /// **Specification:** Provides direct access to the city name for SwiftUI views.
    /// This is a computed property that extracts the value synchronously.
    var cityNameValue: String {
        extractCityName(from: city.displayName)
    }
    
    /// Convenience property for SwiftUI binding - weather description.
    var descriptionValue: String {
        city.description.capitalized
    }
    
    /// Convenience property for SwiftUI binding - temperature.
    var temperatureValue: String {
        city.temperature
    }
    
    /// Convenience property for SwiftUI binding - humidity.
    var humidityValue: String {
        city.humidity
    }
    
    /// Convenience property for SwiftUI binding - wind speed.
    var windSpeedValue: String {
        city.wind
    }
    
    /// Convenience property for SwiftUI binding - formatted update time.
    var formattedUpdateTimeValue: String {
        formatUpdateTime(city.updatedAt)
    }
    
    // MARK: - Private Properties
    
    /// The city entity containing weather information.
    private let city: City
    
    /// Use case for fetching weather icon images.
    private let fetchWeatherIconUseCase: FetchWeatherIconUseCaseProtocol
    
    /// Cancellables for managing Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with a city entity and use case.
    ///
    /// **Specification:** Sets up Combine subscriptions for input subjects and
    /// automatically triggers initial weather icon loading.
    ///
    /// - Parameters:
    ///   - city: The city entity to display
    ///   - fetchWeatherIconUseCase: The use case for fetching weather icons
    init(city: City, fetchWeatherIconUseCase: FetchWeatherIconUseCaseProtocol) {
        self.city = city
        self.fetchWeatherIconUseCase = fetchWeatherIconUseCase
        
        setupBindings()
        
        // Automatically load icon on initialization
        loadWeatherIconSubject.send()
    }
    
    // MARK: - Private Methods
    
    /// Sets up Combine bindings for input subjects.
    ///
    /// **Specification:** Subscribes to input subjects and triggers appropriate actions
    /// when events are received.
    private func setupBindings() {
        // Handle load weather icon requests
        loadWeatherIconSubject
            .sink { [weak self] _ in
                self?.loadWeatherIcon()
            }
            .store(in: &cancellables)
        
        // Handle retry requests
        retryLoadIconSubject
            .sink { [weak self] _ in
                self?.loadWeatherIcon()
            }
            .store(in: &cancellables)
    }
    
    /// Extracts the city name from the display name (removes country code).
    ///
    /// **Specification:** Extracts the city name from the display name,
    /// removing the country code if present (e.g., "London, GB" -> "London").
    ///
    /// - Parameter displayName: The full display name with country code
    /// - Returns: The city name without country code
    private func extractCityName(from displayName: String) -> String {
        if let commaIndex = displayName.firstIndex(of: ",") {
            return String(displayName[..<commaIndex]).trimmingCharacters(in: .whitespaces)
        }
        return displayName
    }
    
    /// Formats the update timestamp for display.
    ///
    /// **Specification:** Formats the update timestamp as "DD.MM.YYYY - HH:mm"
    /// matching the design specification.
    ///
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
    
    /// Extracts the icon code from the city's icon URL.
    ///
    /// **Specification:** Extracts the icon code (e.g., "01d") from the stored iconURL
    /// which may be in various formats (wn with @2x, w format, etc.).
    ///
    /// - Returns: The icon code string, or "01d" as default
    private var iconCode: String {
        guard let iconURL = city.iconURL else {
            return "01d"
        }
        
        let urlString = iconURL.absoluteString
        
        // Extract icon code from various URL formats
        // Format 1: https://openweathermap.org/img/wn/01d@2x.png
        // Format 2: https://openweathermap.org/img/w/01d.png
        // We need to extract "01d"
        
        let patterns = [
            #"/img/wn/([a-z0-9]+)@"#,  // Matches wn format with @2x
            #"/img/w/([a-z0-9]+)\.png"#, // Matches w format
            #"/img/wn/([a-z0-9]+)\.png"#  // Matches wn format without @2x
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.utf16.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: urlString) {
                    return String(urlString[swiftRange])
                }
            }
        }
        
        // Fallback to default icon code
        return "01d"
    }
    
    /// Loads the weather icon image using the use case.
    ///
    /// **Specification:** Fetches the icon image data from the API and converts it
    /// to a SwiftUI Image for display. Handles loading states and errors.
    private func loadWeatherIcon() {
        let code = iconCode
        isLoadingIconValue = true
        iconErrorValue = nil
        
        Task { @MainActor in
            do {
                let imageData = try await fetchWeatherIconUseCase.execute(iconCode: code)
                if let uiImage = UIImage(data: imageData) {
                    self.weatherIconImageValue = Image(uiImage: uiImage)
                } else {
                    self.iconErrorValue = "Failed to decode image data"
                }
                self.isLoadingIconValue = false
            } catch {
                self.iconErrorValue = error.localizedDescription
                self.isLoadingIconValue = false
            }
        }
    }
}
