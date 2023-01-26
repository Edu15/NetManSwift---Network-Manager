import Foundation

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
    
    public init(session: NetworkSession = URLSession.shared) {
        self.session = session
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
    
extension NetworkManager: NetworkManaging {
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
    
    @available(iOS 13, *)
    public func perform<ResultType: Decodable>(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) async throws -> ResultType {
        let responseData: Data
        do {
            let (data, _) = try await session.data(for: request)
            responseData = data
        } catch {
            throw mapToNetworkError(response: nil, error: error)
        }
        
        do {
            return try decodeData(responseData, keyDecodingStrategy: keyDecodingStrategy)
        } catch {
            throw NetworkError.decodeError(error)
        }
    }
}
