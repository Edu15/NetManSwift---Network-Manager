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
    
    func requestNextCatFact() {
        let request = URLRequest(url: URL(string: "https://catfact.ninja/fact")!)
        let networkManager = NetworkManager()
        isLoading = true
        networkManager.perform(request, keyDecodingStrategy: .useDefaultKeys) { (result: Result<CatFact, NetworkError>) -> Void in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                switch result {
                case .success(let catFact):
                    self?.fact = catFact.fact
                case .failure(let error):
                    self?.showAlert = true
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
