import Foundation
//import os


public protocol NetworkSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    
    @available(iOS 13, *)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
extension URLSession: NetworkSession {}

public protocol NetworkManaging {
    func perform<ResultType: Decodable>(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy,
        completion: @escaping ((Result<ResultType, NetworkError>) -> Void)
    )
    
    @available(iOS 13, *)
    func perform<ResultType: Decodable>(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) async throws -> ResultType
}

public struct NetworkManager {
    public let session: NetworkSession
//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")

    public init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    public func perform<ResultType: Decodable>(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy,
        completion: @escaping ((Result<ResultType, NetworkError>) -> Void)
    ) {
        let dataTask = session.dataTask(with: request) { data, response, error in
            if let error = error {
                let networkError = mapToNetworkError(response: response, error: error)
                completion(.failure(networkError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noContent(response)))
                return
            }
            
            do {
                let decodedData: ResultType = try decodeData(data, keyDecodingStrategy: keyDecodingStrategy)
                completion(.success(decodedData))
            } catch {
                completion(.failure(.decodeError(error)))
            }
        }
        dataTask.resume()
    }
    
//    @available(iOS 13, *)
//    public func perform<ResultType: Decodable>(
//        _ request: URLRequest,
//        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
//    ) async throws -> ResultType {
//        try await withCheckedThrowingContinuation { continuation in
//            let dataTask = session.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    let networkError = mapToNetworkError(response: response, error: error)
//                    continuation.resume(throwing: networkError)
//                    return
//                }
//
//                if let data = data {
//                    do {
//                        let decodedData: ResultType = try decodeData(data, keyDecodingStrategy: keyDecodingStrategy)
//                        continuation.resume(with: .success(decodedData))
//                    } catch {
//                        continuation.resume(throwing: NetworkError.decodeError)
//                    }
//                    return
//                }
//
//                continuation.resume(throwing: NetworkError.noContent(response))
//            }
//            dataTask.resume()
//        }
//    }
//
    @available(iOS 13, *)
    public func perform<ResultType: Decodable>(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) async throws -> ResultType {
        let dataResponse: Data
        do {
            let (data, _) = try await session.data(for: request)
            dataResponse = data
        } catch {
            throw mapToNetworkError(response: nil, error: error)
        }
        
        do {
            return try decodeData(dataResponse, keyDecodingStrategy: keyDecodingStrategy)
        } catch {
            throw NetworkError.decodeError(error)
        }
    }
    
    private func decodeData<ResultType: Decodable>(
        _ data: Data,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) throws -> ResultType {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        return try decoder.decode(ResultType.self, from: data)
    }
    
    private func mapToNetworkError(response: URLResponse?, error: Error) -> NetworkError {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            return .undefined(error)
        }

        switch statusCode {
        case 400..<500:
            return .badRequest
        case 500..<600:
            return .serverError
        default:
            return .undefined(error)
        }
    }
}
