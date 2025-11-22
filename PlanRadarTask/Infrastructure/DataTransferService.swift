//
//  DataTransferService.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Data transfer layer error types.
///
/// **Specification Interpretation:**
/// These errors represent failures in the data transfer layer, which sits above
/// the network layer and handles data transformation (decoding, mapping, etc.).
///
/// **Access Control:**
/// - Internal enum: Used within the infrastructure module
enum DataTransferError: Error {
    /// No response data was received
    case noResponse
    /// Failed to parse/decode the response data
    case parsing(Error)
    /// Network layer failure
    case networkFailure(NetworkError)
    /// Resolved network error (transformed by error resolver)
    case resolvedNetworkFailure(Error)
}

/// Protocol for data transfer service implementations.
///
/// **Specification Interpretation:**
/// This protocol abstracts data transformation operations, handling the conversion
/// from raw network data to domain models. It provides type-safe request methods
/// with automatic decoding.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol DataTransferService {
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E
    ) async throws -> T where E.Response == T
    
    func request<E: ResponseRequestable>(
        with endpoint: E
    ) async throws where E.Response == Void
}

/// Protocol for resolving network errors to domain-specific errors.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol DataTransferErrorResolver {
    /// Resolves a network error to a domain-specific error.
    ///
    /// - Parameter error: The network error to resolve
    /// - Returns: A resolved error (may be the same or transformed)
    func resolve(error: NetworkError) -> Error
}

/// Protocol for decoding response data.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol ResponseDecoder {
    /// Decodes response data to a decodable type.
    ///
    /// - Parameter data: The data to decode
    /// - Returns: The decoded object
    /// - Throws: Decoding errors if the data cannot be decoded
    func decode<T: Decodable>(_ data: Data) throws -> T
}

/// Protocol for logging data transfer errors.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol DataTransferErrorLogger {
    /// Logs a data transfer error.
    ///
    /// - Parameter error: The error to log
    func log(error: Error)
}

/// Default implementation of DataTransferService.
///
/// **Specification Interpretation:**
/// This class handles the transformation of network responses into domain models.
/// It coordinates between the network layer, decoders, and error handlers to
/// provide a clean, type-safe API for data transfer operations.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
/// - Private dependencies: All dependencies are encapsulated
final class DefaultDataTransferService {
    
    /// Network service for executing requests
    private let networkService: NetworkService
    
    /// Error resolver for transforming network errors
    private let errorResolver: DataTransferErrorResolver
    
    /// Error logger for debugging
    private let errorLogger: DataTransferErrorLogger
    
    init(
        with networkService: NetworkService,
        errorResolver: DataTransferErrorResolver = DefaultDataTransferErrorResolver(),
        errorLogger: DataTransferErrorLogger = DefaultDataTransferErrorLogger()
    ) {
        self.networkService = networkService
        self.errorResolver = errorResolver
        self.errorLogger = errorLogger
    }
}

extension DefaultDataTransferService: DataTransferService {
    
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E
    ) async throws -> T where E.Response == T {
        
        do {
            let data = try await networkService.request(endpoint: endpoint)
            return try decode(data: data, decoder: endpoint.responseDecoder)
        } catch let error as NetworkError {
            self.errorLogger.log(error: error)
            let resolvedError = self.resolve(networkError: error)
            throw resolvedError
        } catch {
            self.errorLogger.log(error: error)
            throw error
        }
    }
    
    func request<E>(
        with endpoint: E
    ) async throws where E : ResponseRequestable, E.Response == Void {
        
        do {
            _ = try await networkService.request(endpoint: endpoint)
        } catch let error as NetworkError {
            self.errorLogger.log(error: error)
            let resolvedError = self.resolve(networkError: error)
            throw resolvedError
        } catch {
            self.errorLogger.log(error: error)
            throw error
        }
    }

    // MARK: - Private
    private func decode<T: Decodable>(
        data: Data?,
        decoder: ResponseDecoder
    ) throws -> T {
        guard let data = data else { throw DataTransferError.noResponse }
        return try decoder.decode(data)
    }
    
    private func resolve(networkError error: NetworkError) -> DataTransferError {
        let resolvedError = self.errorResolver.resolve(error: error)
        return resolvedError is NetworkError
        ? .networkFailure(error)
        : .resolvedNetworkFailure(resolvedError)
    }
}

// MARK: - Logger

/// Default implementation of DataTransferErrorLogger.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
final class DefaultDataTransferErrorLogger: DataTransferErrorLogger {
    /// Initializes the logger.
    init() { }
    
    /// Logs errors to the console in DEBUG builds.
    ///
    /// - Parameter error: The error to log
    func log(error: Error) {
        printIfDebug("-------------")
        printIfDebug("\(error)")
    }
}

// MARK: - Error Resolver

/// Default implementation of DataTransferErrorResolver.
///
/// **Specification:** Returns network errors as-is without transformation.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
class DefaultDataTransferErrorResolver: DataTransferErrorResolver {
    /// Initializes the resolver.
    init() { }
    
    /// Resolves network errors (returns unchanged).
    ///
    /// - Parameter error: The network error
    /// - Returns: The same error
    func resolve(error: NetworkError) -> Error {
        return error
    }
}

// MARK: - Response Decoders

/// JSON decoder implementation.
///
/// **Specification:** Uses Foundation's JSONDecoder to decode JSON responses.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
class JSONResponseDecoder: ResponseDecoder {
    /// The underlying JSON decoder
    private let jsonDecoder = JSONDecoder()
    
    /// Initializes the decoder.
    init() { }
    
    /// Decodes JSON data to a decodable type.
    ///
    /// - Parameter data: The JSON data to decode
    /// - Returns: The decoded object
    /// - Throws: Decoding errors if the JSON is invalid
    func decode<T: Decodable>(_ data: Data) throws -> T {
        return try jsonDecoder.decode(T.self, from: data)
    }
}

/// Raw data decoder implementation.
///
/// **Specification:** Returns raw Data objects without decoding.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
class RawDataResponseDecoder: ResponseDecoder {
    /// Initializes the decoder.
    init() { }
    
    enum CodingKeys: String, CodingKey {
        case `default` = ""
    }
    func decode<T: Decodable>(_ data: Data) throws -> T {
        if T.self is Data.Type, let data = data as? T {
            return data
        } else {
            let context = DecodingError.Context(
                codingPath: [CodingKeys.default],
                debugDescription: "Expected Data type"
            )
            throw Swift.DecodingError.typeMismatch(T.self, context)
        }
    }
}
