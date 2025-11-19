import SwiftUI

struct StopsView: View {
    
    @StateObject var viewModel: StopsViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando paradas...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Reintentar") {
                            viewModel.fetchStops()
                        }
                        .padding(.top)
                    }
                } else {
                    List(viewModel.stops) { stop in
                        VStack(alignment: .leading) {
                            Text(stop.name)
                                .font(.headline)
                            Text("ID: \(stop.stopId)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Paradas")
            .onAppear {
                // Fetch stops only if the list is empty
                if viewModel.stops.isEmpty {
                    viewModel.fetchStops()
                }
            }
        }
    }
}