//
//  AppDIContainer.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation
import UIKit

final class AppDIContainer {
    
    lazy var appConfiguration = AppConfiguration()
    
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
}
