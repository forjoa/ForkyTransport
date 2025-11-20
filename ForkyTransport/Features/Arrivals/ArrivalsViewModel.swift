import Foundation
import SwiftUI
import Combine

@MainActor
final class ArrivalsViewModel: ObservableObject {
    @Published private(set) var arrivalTimes: [BusArrival] = []
    @Published private(set) var stopInfo: StopInfo?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var lastUpdateTime: Date?

    private let stopId: String
    private let apiService: EMTAPIServiceProtocol
    private let dbService: DatabaseServiceProtocol // To get the token
    private var cancellables = Set<AnyCancellable>()

    init(stopId: String, apiService: EMTAPIServiceProtocol, dbService: DatabaseServiceProtocol) {
        self.stopId = stopId
        self.apiService = apiService
        self.dbService = dbService
    }
    
    func fetchArrivals() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        dbService.getToken()
            .flatMap { [weak self] token -> AnyPublisher<ArrivalResponse, Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                guard let token = token else { return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher() }

                return self.apiService.getArrivalTimes(stopId: self.stopId, accessToken: token.accessToken)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Error al cargar llegadas: \(error.localizedDescription)"
                    }
                }
            }, receiveValue: { [weak self] response in
                DispatchQueue.main.async {
                    self?.arrivalTimes = response.data.first?.arrive ?? []
                    self?.stopInfo = response.data.first?.stopInfo?.first
                    self?.lastUpdateTime = Date() // Update the last update time
                    if self?.arrivalTimes.isEmpty == true {
                        self?.errorMessage = "No hay llegadas previstas para esta parada."
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    /// Converts seconds to a human-readable format (e.g., "3 min", "30 seg").
    func formatArrivalTime(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seg"
        } else {
            let minutes = seconds / 60
            return "\(minutes) min"
        }
    }
    
    /// Converts line color hex string to SwiftUI Color.
    func colorFromHexString(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }

    /// Calculates the time interval since last update
    func timeSinceLastUpdate() -> String {
        guard let lastUpdate = lastUpdateTime else {
            return "Nunca actualizado"
        }

        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdate)

        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60

        return "\(minutes)m \(seconds)s"
    }
}
