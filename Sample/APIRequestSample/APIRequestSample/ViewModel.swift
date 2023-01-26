import Foundation
import NetMan

struct CatFact: Decodable {
    let fact: String
    let length: Int
}

final class ViewModel: ObservableObject {
    @Published var fact: String = "Tap on \"Next\" to get a fact"
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var errorMessage: String = ""
    
    private lazy var networkManager = NetworkManager()
    private let request = URLRequest(url: URL(string: "https://catfact.ninja/fact")!)
    
    func requestNextCatFact1() {
        isLoading = true
        Task {
            do {
                let result: CatFact = try await networkManager.perform(request, keyDecodingStrategy: .useDefaultKeys)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.fact = result.fact
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert = true
                    self.errorMessage = self.describeError(error)
                }
            }
        }
    }
    
    func requestNextCatFact2() {
        isLoading = true
        networkManager.perform(request, keyDecodingStrategy: .useDefaultKeys) { (result: Result<CatFact, NetworkError>) -> Void in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                switch result {
                case .success(let catFact):
                    self?.fact = catFact.fact
                case .failure(let error):
                    self?.showAlert = true
                    self?.errorMessage = self?.describeError(error) ?? ""
                }
            }
        }
    }
    
    private func describeError(_ error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "Error"
        }
        switch networkError {
        case .decodeError(let error):
            return "Decode error: \(error)"
        case .noContent(let response):
            return "No content returned. Response: \(response.debugDescription)"
        case .badRequest:
            return "API error 4XX"
        case .serverError:
            return "API error 5XX"
        case .undefined(let error):
            return "Undefined API error: \(error)"
        }
    }
}
