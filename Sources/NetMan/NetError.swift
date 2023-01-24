import Foundation

public enum NetworkError : Error {
    case decodeError
    case noContent(URLResponse?)
    case badRequest
    case serverError
    case undefined(Error)
}
