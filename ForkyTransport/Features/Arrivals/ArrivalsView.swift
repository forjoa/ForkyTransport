import SwiftUI

struct ArrivalsView: View {
    @StateObject var viewModel: ArrivalsViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Cargando llegadas...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Reintentar") {
                        viewModel.fetchArrivals()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List {
                    if let stopInfo = viewModel.stopInfo {
                        Section(header: Text("Parada \(stopInfo.stopId ?? "N/A"): \(stopInfo.stopName ?? "Nombre Desconocido")")) {
                            if let direction = stopInfo.direction?.trimmingCharacters(in: .whitespacesAndNewlines), !direction.isEmpty {
                                Text("Dirección: \(direction)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let lines = stopInfo.lines, !lines.isEmpty {
                                HStack {
                                    Text("Líneas:")
                                    ForEach(lines) { lineDetail in
                                        if let label = lineDetail.label, let colorHex = lineDetail.color {
                                            Text(label)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(viewModel.colorFromHexString(colorHex))
                                                .foregroundColor(.white)
                                                .cornerRadius(5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Próximas Llegadas")) {
                        if viewModel.arrivalTimes.isEmpty {
                            Text("No hay autobuses próximos.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.arrivalTimes) { arrival in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Línea \(arrival.line) - \(arrival.destination)")
                                            .font(.headline)
                                        Text("Distancia: \(arrival.distanceBus) metros")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(viewModel.formatArrivalTime(seconds: arrival.estimateArrive))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(arrival.estimateArrive < 60 ? .red : .primary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Llegadas")
        .onAppear {
            viewModel.fetchArrivals()
        }
    }
}
