//
//  AppConfiguration.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

final class AppConfiguration {
    
    lazy var apiBaseURL: String = {
        guard let apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !apiBaseURL.isEmpty else {
            fatalError("ApiBaseURL must not be empty in plist")
        }
        return apiBaseURL
    }()
    
    lazy var imagesBaseURL: String = {
        guard let imageBaseURL = Bundle.main.object(forInfoDictionaryKey: "IMAGE_BASE_URL") as? String,
              !imageBaseURL.isEmpty else {
            fatalError("ImageBaseURL must not be empty in plist")
        }
        return imageBaseURL
    }()

    lazy var apiKey: String = {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !apiKey.isEmpty else {
            fatalError("API_KEY must not be empty in plist")
        }
        return apiKey
    }()
}
