import Foundation
//import os

public protocol NetworkManaging {
    func perform<ResultType: Decodable>(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy,
        completion: @escaping ((Result<ResultType, NetworkError>) -> Void)
    )
}

public struct NetworkManager {
    public let session: URLSession
//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")

    public init(session: URLSession = URLSession.shared) {
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

            if let data = data {
                do {
                    let decodedData: ResultType = try decodeData(data, keyDecodingStrategy: keyDecodingStrategy)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(.decodeError))
                }
                return
            }

            completion(.failure(.noContent(response)))
        }
//        if #available(macOS 12.0, *) {
//            dataTask.delegate = LoadTracker()
//        }

        dataTask.resume()
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
