//
//  AppDIContainer.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import CoreData

final class AppDIContainer {
    
    lazy var appConfiguration = AppConfiguration()
    
    // MARK: - Persistence
    private lazy var persistenceController = PersistenceController.shared
    lazy var citiesStorage: CitiesStorage = {
        CoreDataCitiesStorage(context: persistenceController.container.viewContext)
    }()
    
    // MARK: - Network
    lazy var apiDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(
            baseURL: appConfiguration.apiBaseURL,
            queryParameters: ["appid": appConfiguration.apiKey]
        )
        let apiDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: apiDataNetwork)
    }()
    
    lazy var imageDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(baseURL: appConfiguration.imagesBaseURL)
        let imageNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: imageNetwork)
    }()
    
    // MARK: - Cities
    lazy var citiesRepository: CitiesRepository = {
        CitiesRepositoryImpl(storage: citiesStorage)
    }()
    
    lazy var fetchCitiesUseCase = FetchCitiesUseCase(repository: citiesRepository)
    lazy var deleteCityUseCase = DeleteCityUseCase(repository: citiesRepository)
    
    // MARK: - Search
    lazy var searchRepository: SearchRepository = {
        SearchRepositoryImpl(network: apiDataTransferService)
    }()
    
    lazy var searchCityUseCase = SearchCityUseCase(repository: searchRepository)
    lazy var addCityUseCase = AddCityUseCase(storage: citiesStorage)

    lazy var searchFlowCoordinator = SearchFlowCoordinator(
        searchUseCase: searchCityUseCase,
        addUseCase: addCityUseCase
    )
}
