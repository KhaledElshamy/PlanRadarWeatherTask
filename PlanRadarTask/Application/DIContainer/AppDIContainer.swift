//
//  AppDIContainer.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

/// Dependency Injection Container that provides centralized access to all application dependencies.
///
/// **Specification Interpretation:**
/// This container follows the Dependency Injection pattern to manage the creation and lifecycle
/// of all services, repositories, and use cases. It ensures that dependencies are created lazily
/// and shared appropriately across the application, promoting testability and maintainability.
///
/// **Access Control:**
/// - Internal class: Used only within the application module
/// - Lazy properties: Dependencies are created on-demand to optimize startup performance
/// - Private persistence controller: Core Data stack is encapsulated
final class AppDIContainer {
    
    /// Application configuration provider
    lazy var appConfiguration = AppConfiguration()
    
    // MARK: - Persistence
    
    /// Core Data persistence controller (private to prevent direct access)
    private lazy var persistenceController = PersistenceController.shared
    
    /// Storage interface for city data persistence operations.
    /// 
    /// **Specification:** Provides CRUD operations for cities using Core Data.
    lazy var citiesStorage: CitiesStorage = {
        CoreDataCitiesStorage(context: persistenceController.container.viewContext)
    }()
    
    // MARK: - Network
    
    /// Data transfer service for API requests with authentication.
    /// 
    /// **Specification:** Configured with the API base URL and API key as a query parameter.
    /// All requests to the weather API will include the appid parameter automatically.
    lazy var apiDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(
            baseURL: appConfiguration.apiBaseURL,
            queryParameters: ["appid": appConfiguration.apiKey]
        )
        let apiDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: apiDataNetwork)
    }()
    
    /// Data transfer service for image resource requests.
    /// 
    /// **Specification:** Configured with the image base URL for fetching weather icons.
    lazy var imageDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(baseURL: appConfiguration.imagesBaseURL)
        let imageNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: imageNetwork)
    }()
    
    // MARK: - Cities
    
    /// Repository for city-related operations (fetch, delete).
    /// 
    /// **Specification:** Implements the CitiesRepository protocol, providing access to
    /// locally stored cities through the storage layer.
    lazy var citiesRepository: CitiesRepository = {
        CitiesRepositoryImpl(storage: citiesStorage)
    }()
    
    /// Use case for fetching all saved cities from local storage.
    lazy var fetchCitiesUseCase = FetchCitiesUseCase(repository: citiesRepository)
    
    /// Use case for deleting a city from local storage.
    lazy var deleteCityUseCase = DeleteCityUseCase(repository: citiesRepository)
    
    // MARK: - Search
    
    /// Repository for searching cities via the weather API.
    /// 
    /// **Specification:** Implements the SearchRepository protocol, providing access to
    /// remote weather data through the network layer.
    lazy var searchRepository: SearchRepository = {
        SearchRepositoryImpl(network: apiDataTransferService)
    }()
    
    /// Use case for searching city weather information via API.
    lazy var searchCityUseCase = SearchCityUseCase(repository: searchRepository)
    
    /// Use case for adding a city to local storage after successful search.
    lazy var addCityUseCase = AddCityUseCase(storage: citiesStorage)

    /// Flow coordinator for the search module navigation.
    lazy var searchFlowCoordinator = SearchFlowCoordinator(
        searchUseCase: searchCityUseCase,
        addUseCase: addCityUseCase
    )
    
    // MARK: - City Details
    
    /// Repository for fetching weather icon images.
    ///
    /// **Specification:** Implements the WeatherIconRepository protocol, providing access to
    /// weather icon images through the image API network layer.
    lazy var weatherIconRepository: WeatherIconRepository = {
        WeatherIconRepositoryImpl(network: imageDataTransferService)
    }()
    
    /// Use case for fetching weather icon images.
    lazy var fetchWeatherIconUseCase = FetchWeatherIconUseCase(repository: weatherIconRepository)
}
