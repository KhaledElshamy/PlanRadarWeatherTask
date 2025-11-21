import Foundation

public struct SearchResult: Identifiable, Equatable {
    public let id: String
    public let city: City

    public init(city: City) {
        self.city = city
        self.id = city.displayName
    }
}

