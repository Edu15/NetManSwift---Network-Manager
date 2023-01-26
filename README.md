# NetMan

A basic network manager to perform API calls.

## Examples of use

    import NetMan

    let request = URLRequest(url: URL(string: "https://catfact.ninja/fact")!)

    NetworkManager().perform(request, keyDecodingStrategy: .useDefaultKeys) { (result: Result<CatFact, NetworkError>) -> Void in
        DispatchQueue.main.async {
            switch result {
            case .success(let catFact):
                // Present cat fact
            case .failure(let error):
                // Present error
            }
        }
    }
    
Using async await:

    let request = URLRequest(url: URL(string: "https://catfact.ninja/fact")!)

    Task {
        do {
            let result: CatFact = try await NetworkManager().perform(request, keyDecodingStrategy: .useDefaultKeys)
            DispatchQueue.main.async {
                // Present cat fact
            }
        } catch {
            DispatchQueue.main.async {
                // Present error
            }
        }
    }
