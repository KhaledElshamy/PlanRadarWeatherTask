//
//  NetworkService.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

/// Network layer error types.
///
/// **Specification Interpretation:**
/// These errors represent various failure scenarios that can occur during network
/// operations. They provide detailed information to help with debugging and user-facing
/// error messages.
///
/// **Access Control:**
/// - Internal enum: Used within the infrastructure module
enum NetworkError: Error, Equatable {
    /// HTTP error with status code and optional response data
    case error(statusCode: Int, data: Data?)
    /// No internet connection available
    case notConnected
    /// Request was cancelled
    case cancelled
    /// Generic error wrapping other error types
    /// Note: Equatable conformance compares error descriptions since Error is not Equatable
    case generic(Error)
    /// Failed to generate a valid URL from the endpoint
    case urlGeneration
    
    /// Equatable conformance for testing purposes.
    ///
    /// **Note:** The `generic` case compares error descriptions since `Error` is not `Equatable`.
    /// **Note:** Data comparison uses `==` which works for Data types in Swift.
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.error(let lhsCode, let lhsData), .error(let rhsCode, let rhsData)):
            // Compare status codes and data (handles nil cases)
            guard lhsCode == rhsCode else { return false }
            if lhsData == nil && rhsData == nil {
                return true
            }
            guard let lhsData = lhsData, let rhsData = rhsData else {
                return false
            }
            return lhsData == rhsData
        case (.notConnected, .notConnected):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.urlGeneration, .urlGeneration):
            return true
        case (.generic(let lhsError), .generic(let rhsError)):
            // Compare error descriptions since Error is not Equatable
            let lhsNSError = lhsError as NSError
            let rhsNSError = rhsError as NSError
            return lhsNSError.domain == rhsNSError.domain &&
                   lhsNSError.code == rhsNSError.code &&
                   lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Protocol for network service implementations.
///
/// **Specification Interpretation:**
/// This protocol abstracts network operations, allowing for easy testing and swapping
/// of network implementations. The service executes requests and returns raw Data.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol NetworkService {
    /// Executes a network request for the given endpoint.
    ///
    /// - Parameter endpoint: The endpoint configuration
    /// - Returns: Optional response data
    /// - Throws: NetworkError for various failure scenarios
    func request(endpoint: Requestable) async throws -> Data?
}

/// Protocol for cancellable network operations.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol NetworkCancellable {
    /// Cancels the ongoing network operation
    func cancel()
}

/// Protocol for network error logging.
///
/// **Specification Interpretation:**
/// This protocol allows for pluggable logging implementations, enabling different
/// logging strategies (console, file, remote) without changing the network layer.
///
/// **Access Control:**
/// - Internal protocol: Used within the infrastructure module
protocol NetworkErrorLogger {
    /// Logs a network request before it is sent.
    ///
    /// - Parameter request: The URLRequest to log
    func log(request: URLRequest)
    
    /// Logs network response data.
    ///
    /// - Parameters:
    ///   - data: The response data
    ///   - response: The URLResponse object
    func log(responseData data: Data?, response: URLResponse?)
    
    /// Logs a network error.
    ///
    /// - Parameter error: The error to log
    func log(error: Error)
}

/// Default implementation of NetworkService using Objective-C network layer.
///
/// **Specification Interpretation:**
/// This class bridges Swift's async/await concurrency model with the Objective-C
/// network implementation. It handles request execution, error resolution, and logging
/// while maintaining a clean Swift interface.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
/// - Private dependencies: All dependencies are encapsulated
final class DefaultNetworkService {
    
    /// Network configuration (base URL, headers, query parameters)
    private let config: NetworkConfigurable
    
    /// Objective-C network performer for actual request execution
    private let performer: ObjCNetworkPerformer
    
    /// Logger for network operations
    private let logger: NetworkErrorLogger
    
    /// Initializes the network service with dependencies.
    ///
    /// - Parameters:
    ///   - config: Network configuration
    ///   - performer: Objective-C network performer (defaults to new instance)
    ///   - logger: Error logger (defaults to console logger)
    init(
        config: NetworkConfigurable,
        performer: ObjCNetworkPerformer = ObjCNetworkPerformer(),
        logger: NetworkErrorLogger = DefaultNetworkErrorLogger()
    ) {
        self.config = config
        self.performer = performer
        self.logger = logger
    }
    
    /// Executes a URLRequest and returns the response data.
    ///
    /// **Specification:** Logs the request, executes it via the Objective-C bridge,
    /// logs the response, and resolves any errors to NetworkError types.
    ///
    /// - Parameter request: The URLRequest to execute
    /// - Returns: Optional response data
    /// - Throws: NetworkError for various failure scenarios
    private func execute(request: URLRequest) async throws -> Data? {
        logger.log(request: request)
        do {
            let (data, response) = try await performer.response(for: request)
            logger.log(responseData: data, response: response)
            return data
        } catch {
            let networkError = resolve(error: error)
            logger.log(error: networkError)
            throw networkError
        }
    }
    
    /// Resolves generic errors to specific NetworkError types.
    ///
    /// **Specification:** Maps Objective-C NSError types and URLError codes to
    /// appropriate NetworkError cases for consistent error handling.
    ///
    /// - Parameter error: The error to resolve
    /// - Returns: A NetworkError representing the failure
    private func resolve(error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        let nsError = error as NSError
        if nsError.domain == ObjCNetworkErrorDomain,
           let statusCode = nsError.userInfo[ObjCNetworkStatusCodeKey] as? Int {
            let responseData = nsError.userInfo[ObjCNetworkResponseDataKey] as? Data
            return .error(statusCode: statusCode, data: responseData)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
        case .notConnectedToInternet: return .notConnected
        case .cancelled: return .cancelled
        default: return .generic(error)
        }
        }

        return .generic(error)
    }
}

extension DefaultNetworkService: NetworkService {
    
    func request(endpoint: Requestable) async throws -> Data? {
        // Only catch URL generation errors, let network errors propagate
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest(with: config)
        } catch let error as RequestGenerationError {
            // URL generation failed, convert to NetworkError
            throw NetworkError.urlGeneration
        } catch {
            // If it's not a RequestGenerationError, it might be an encoding error
            // from queryParametersEncodable?.toDictionary() or bodyParametersEncodable?.toDictionary()
            // These should also be treated as URL generation failures
            throw NetworkError.urlGeneration
        }
        
        // Execute request - network errors will be resolved and thrown as NetworkError
        return try await execute(request: urlRequest)
    }
}

// MARK: - Logger

/// Default implementation of NetworkErrorLogger for console output.
///
/// **Specification Interpretation:**
/// This logger prints network requests, responses, and errors to the console.
/// In DEBUG builds, it provides detailed information for debugging. In release
/// builds, it remains silent to avoid performance overhead.
///
/// **Access Control:**
/// - Internal class: Used within the infrastructure module
final class DefaultNetworkErrorLogger: NetworkErrorLogger {
    /// Initializes the logger.
    init() { }

    func log(request: URLRequest) {
        print("-------------")
        print("request: \(request.url!)")
        print("headers: \(request.allHTTPHeaderFields!)")
        print("method: \(request.httpMethod!)")
        if let httpBody = request.httpBody, let result = ((try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: AnyObject]) as [String: AnyObject]??) {
            printIfDebug("body: \(String(describing: result))")
        } else if let httpBody = request.httpBody, let resultString = String(data: httpBody, encoding: .utf8) {
            printIfDebug("body: \(String(describing: resultString))")
        }
    }

    func log(responseData data: Data?, response: URLResponse?) {
        guard let data = data else { return }
        if let dataDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            printIfDebug("responseData: \(String(describing: dataDict))")
        }
    }

    func log(error: Error) {
        printIfDebug("\(error)")
    }
}

// MARK: - NetworkError extension

extension NetworkError {
    /// Convenience property to check if the error is a 404 Not Found.
    var isNotFoundError: Bool { return hasStatusCode(404) }
    
    /// Checks if the error has a specific HTTP status code.
    ///
    /// - Parameter codeError: The status code to check
    /// - Returns: True if the error matches the status code
    func hasStatusCode(_ codeError: Int) -> Bool {
        switch self {
        case let .error(code, _):
            return code == codeError
        default: return false
        }
    }
}

extension Dictionary where Key == String {
    func prettyPrint() -> String {
        var string: String = ""
        if let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) {
            if let nstr = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                string = nstr as String
            }
        }
        return string
    }
}

func printIfDebug(_ string: String) {
    #if DEBUG
    print(string)
    #endif
}

// MARK: - ObjC Network Bridge

private extension ObjCNetworkPerformer {
    func response(for request: URLRequest) async throws -> (Data?, URLResponse?) {
        try await withCheckedThrowingContinuation { continuation in
            performRequest(request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (data, response))
                }
            }
        }
    }
}
