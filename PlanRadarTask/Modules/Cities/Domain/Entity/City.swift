import Foundation

public struct City: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let temperature: String
    public let humidity: String
    public let wind: String
    public let description: String
    public let iconURL: URL?
    public let updatedAt: Date

    public init(
        id: String,
        displayName: String,
        temperature: String,
        humidity: String,
        wind: String,
        description: String,
        iconURL: URL?,
        updatedAt: Date
    ) {
        self.id = id
        self.displayName = displayName
        self.temperature = temperature
        self.humidity = humidity
        self.wind = wind
        self.description = description
        self.iconURL = iconURL
        self.updatedAt = updatedAt
    }
}

