import Foundation

final class AppConfiguration {
    
    lazy var apiBaseURL: URL = {
        url(forKey: "API_BASE_URL", description: "ApiBaseURL")
    }()
    
    lazy var imagesBaseURL: URL = {
        url(forKey: "IMAGE_BASE_URL", description: "ImageBaseURL")
    }()

    lazy var apiKey: String = {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !apiKey.isEmpty else {
            fatalError("API_KEY must not be empty in plist")
        }
        return apiKey
    }()

    private func url(forKey key: String, description: String) -> URL {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            fatalError("\(description) must not be empty in plist")
        }
        guard let url = URL(string: value) else {
            fatalError("\(description) must be a valid URL string")
        }
        return url
    }
}

