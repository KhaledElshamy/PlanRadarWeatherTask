//
//  MockResponseDecoder.swift
//  PlanRadarTaskTests
//
//  Created by Khaled Elshamy on 22/11/2025.
//

import Foundation
@testable import PlanRadarTask

/// Mock implementation of ResponseDecoder for testing.
///
/// **Access Control:**
/// - Internal class: Used within test module
final class MockResponseDecoder: ResponseDecoder {
    
    /// The decoded object to return
    var decodedObject: Any?
    
    /// The error to throw when decoding
    var decodingError: Error?
    
    /// Tracks if decode was called
    var decodeCalled = false
    
    /// The data that was passed to decode
    var decodedData: Data?
    
    /// Initializes the mock.
    ///
    /// - Parameters:
    ///   - decodedObject: Object to return when decoding (default: nil)
    ///   - decodingError: Error to throw when decoding (default: nil)
    init(decodedObject: Any? = nil, decodingError: Error? = nil) {
        self.decodedObject = decodedObject
        self.decodingError = decodingError
    }
    
    func decode<T: Decodable>(_ data: Data) throws -> T {
        decodeCalled = true
        decodedData = data
        
        if let error = decodingError {
            throw error
        }
        
        if let decoded = decodedObject as? T {
            return decoded
        }
        
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Mock decoder: No object provided"
            )
        )
    }
}

