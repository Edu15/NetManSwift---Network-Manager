import XCTest
@testable import NetMan

protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

private class NetworkSessionMock: NetworkSession {
    private class URLSessionDataTaskMock: URLSessionDataTask {}
    
    var data: Data?
    var urlResponse: URLResponse?
    var error: Error?
    
    private(set) var request: URLRequest?
    
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.request = request
        completionHandler(data, urlResponse, error)
        return URLSessionDataTaskMock()
    }
}

final class NetworkManagerTests: XCTestCase {
    private struct ExampleDataStructure: Decodable {
        enum Job: String, Decodable {
            case fullTime = "FULL_TIME"
            case partTime = "PART_TIME"
        }
        let name: String
        let age: Int
        let job: Job
    }
    
    private struct ExampleCamelCaseStructure: Decodable {
        let firstName: String
    }
    
    
    func testPerform_whenResponseIsAValidObject() {
        let expectedData = "{test: 5}".data(using: .utf8)!
        
        let urlSession = NetworkSessionMock()
        urlSession.data = expectedData
        let sut = NetworkManager(session: urlSession)
        
        let urlRequest = URLRequest(url: URL(string: "http://abc.com")!)
        let expectation = XCTestExpectation(description: "Perform API request")
        sut.perform(urlRequest, keyDecodingStrategy: .useDefaultKeys) { (result: Result<String, NetworkError>) in
//            guard case let .success(data, response, error) = result else {
//                XCTFail("Expected success on api request")
//            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
