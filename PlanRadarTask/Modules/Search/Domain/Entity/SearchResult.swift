//
//  SearchResult.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Domain entity representing a search result containing a city.
///
/// **Specification Interpretation:**
/// This entity wraps a `City` entity to provide an `Identifiable` result that can be
/// used in SwiftUI views and Combine publishers. It's used to represent the outcome
/// of a successful city search operation.
///
/// **Access Control:**
/// - Public struct: Exposed for use across modules and testing
/// - Conforms to Identifiable: Enables SwiftUI list rendering
/// - Conforms to Equatable: Enables comparison and testing
public struct SearchResult: Identifiable, Equatable {
    public let id: String
    public let city: City

    public init(city: City) {
        self.city = city
        self.id = city.displayName
    }
}

