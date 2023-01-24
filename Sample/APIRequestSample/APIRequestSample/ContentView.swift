import SwiftUI
import NetMan

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "quote.opening")
                    .imageScale(.large)
                
                ZStack {
                    Text(viewModel.fact)
                        .font(.title2)
                        .foregroundColor(viewModel.isLoading ? .gray : .black)
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    }
                }
                
                Image(systemName: "quote.closing")
                    .imageScale(.large)
                
                Button("Next") {
                    viewModel.requestNextCatFact()
                }
                .padding(24)
            }
            .navigationTitle("Cat facts")
            .padding(16)
            .alert(viewModel.errorMessage, isPresented: $viewModel.showAlert) {}
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
