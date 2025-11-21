//
//  NetworkService.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import Foundation

enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case notConnected
    case cancelled
    case generic(Error)
    case urlGeneration
}

protocol NetworkService {
    func request(endpoint: Requestable) async throws -> Data?
}

protocol NetworkCancellable {
    func cancel()
}

protocol NetworkErrorLogger {
    func log(request: URLRequest)
    func log(responseData data: Data?, response: URLResponse?)
    func log(error: Error)
}

/// Executes endpoint-backed requests via the Objective-C bridge while keeping a Swift-friendly surface.
final class DefaultNetworkService {

    private let config: NetworkConfigurable
    private let performer: ObjCNetworkPerformer
    private let logger: NetworkErrorLogger

    init(
        config: NetworkConfigurable,
        performer: ObjCNetworkPerformer = ObjCNetworkPerformer(),
        logger: NetworkErrorLogger = DefaultNetworkErrorLogger()
    ) {
        self.config = config
        self.performer = performer
        self.logger = logger
    }

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
        do {
            let urlRequest = try endpoint.urlRequest(with: config)
            return try await execute(request: urlRequest)
        } catch {
            throw NetworkError.urlGeneration
        }
    }
}

// MARK: - Logger

/// Lightweight logger that keeps the legacy prints for debugging.
final class DefaultNetworkErrorLogger: NetworkErrorLogger {
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
    var isNotFoundError: Bool { return hasStatusCode(404) }

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
