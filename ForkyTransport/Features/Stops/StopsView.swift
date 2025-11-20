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
                    // Search bar
                    SearchBar(text: $viewModel.searchText) {
                        viewModel.applySearchFilter()
                    }
                    .padding(.horizontal)

                    // List with filtered stops
                    List(viewModel.filteredStops) { stop in
                        NavigationLink(destination: ArrivalsView(viewModel: ArrivalsViewModel(stopId: stop.node, apiService: viewModel.apiService, dbService: viewModel.dbService))) {
                            VStack(alignment: .leading, spacing: 2) {
                                // Stop name
                                Text(stop.name)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)

                                // Stop ID and lines
                                HStack {
                                    Text("ID: \(stop.node)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    // Display line badges if they exist
                                    if !stop.lines.isEmpty {
                                        HStack {
                                            ForEach(Array(stop.lines.prefix(3)), id: \.self) { line in
                                                Text(line)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accentColor.opacity(0.1))
                                                    .foregroundColor(.accentColor)
                                                    .cornerRadius(8)
                                                    .lineLimit(1)
                                            }
                                            if stop.lines.count > 3 {
                                                Text("+\(stop.lines.count - 3)")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.2))
                                                    .foregroundColor(.gray)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 2)
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
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.applySearchFilter()
            }
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

// Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Buscar paradas...", text: $text)
                    .foregroundColor(.primary)

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding(.vertical, 4)
    }
}