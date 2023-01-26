import Foundation

public enum NetworkError: Error {
    case decodeError(Error)
    case noContent(URLResponse?)
    case badRequest
    case serverError
    case undefined(Error)
}
