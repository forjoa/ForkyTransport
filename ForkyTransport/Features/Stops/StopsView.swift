import SwiftUI

struct StopsView: View {

    @StateObject var viewModel: StopsViewModel

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading && viewModel.stops.isEmpty {
                    VStack {
                        ProgressView()
                        Text(viewModel.loadingMessage)
                            .padding(.top)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Reintentar Sincronización") {
                            viewModel.syncStops()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(viewModel.stops) { stop in
                        NavigationLink(destination: ArrivalsView(viewModel: ArrivalsViewModel(stopId: stop.node, apiService: viewModel.apiService, dbService: viewModel.dbService))) {
                            VStack(alignment: .leading) {
                                Text(stop.name)
                                    .font(.headline)
                                Text("ID: \(stop.node) | Líneas: \(stop.lines.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onAppear {
                            if stop == viewModel.stops.last {
                                viewModel.loadMoreStops()
                            }
                        }
                    }
                    .refreshable {
                        // Allow pull-to-refresh to re-sync everything.
                        viewModel.syncStops()
                    }
                }
            }
            .navigationTitle("Paradas")
            .onAppear {
                print("[StopsView] onAppear called.")
                // On first appearance, if there are no stops, start the sync process.
                if viewModel.stops.isEmpty {
                    viewModel.syncStops()
                }
            }
        }
    }
}