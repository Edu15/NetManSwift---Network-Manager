import Foundation
//import os

public protocol NetworkManaging {
    associatedtype ResultType : Decodable
    func run(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy,
        completion: @escaping ((Result<ResultType, Error>) -> Void)
    )
}

public struct NetMan<ResultType: Decodable> {

    public let session: URLSession

//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")

    public init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    public func run(
        _ request: URLRequest,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        completion: @escaping ((Result<ResultType, Error>) -> Void)
    ) {

        let dataTask = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(Result.failure(error))
                return
            }

            if let data = data {
                completion(self.decodeData(data, keyDecodingStrategy: keyDecodingStrategy))
                return
            }

            completion(.failure(NetError.undefinedError(response)))
        }
//        if #available(macOS 12.0, *) {
//            dataTask.delegate = LoadTracker()
//        }

        dataTask.resume()
    }

    private func decodeData(
        _ data: Data,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    ) -> Result<ResultType, Error> {

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy

        do {
            let decodedResult = try decoder.decode(ResultType.self, from: data)
            return Result.success(decodedResult)
        } catch {
//            logger.log(error)
            debugPrint(error)
            return Result.failure(NetError.decodeError(error))
        }
    }
}
