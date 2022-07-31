import Foundation

public enum NetError : Error {
    case decodeError(Error)
    case undefinedError(URLResponse?)
}
