import Foundation
import Combine

@MainActor
final class StopsViewModel: ObservableObject {

    @Published private(set) var stops: [StopData] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadingMessage = ""
    @Published var errorMessage: String?

    public let apiService: EMTAPIServiceProtocol
    public let dbService: DatabaseServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    private var currentPage = 0
    private let pageSize = 50
    private var canLoadMorePages = true

    init(apiService: EMTAPIServiceProtocol, dbService: DatabaseServiceProtocol) {
        self.apiService = apiService
        self.dbService = dbService
    }
    
    func syncStops() {
        guard !isLoading else { return }

        self.isLoading = true
        self.errorMessage = nil
        self.loadingMessage = "Sincronizando paradas..."

        dbService.getToken()
            .flatMap { [weak self] token -> AnyPublisher<[StopData], Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                guard let token = token else { return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher() }
                return self.apiService.getAllStops(accessToken: token.accessToken)
            }
            .flatMap { [weak self] stopData -> AnyPublisher<Int, Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                return self.dbService.processAndSaveStops(from: stopData)
            }
            .flatMap { [weak self] savedCount -> AnyPublisher<[StopData], Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                print("\(savedCount) paradas guardadas en la base de datos.")
                self.currentPage = 0
                self.stops = []
                self.canLoadMorePages = true
                return self.dbService.getStopsFromDB(limit: self.pageSize, offset: 0)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Error en la sincronización: \(error.localizedDescription)"
                    }
                }
            }, receiveValue: { [weak self] initialStops in
                DispatchQueue.main.async {
                    self?.stops = initialStops
                    if initialStops.isEmpty {
                        self?.errorMessage = "La API no devolvió paradas."
                    }
                }
            })
            .store(in: &cancellables)
    }

    func loadMoreStops() {
        guard !isLoading, canLoadMorePages else { return }

        isLoading = true
        currentPage += 1
        let offset = currentPage * pageSize

        dbService.getStopsFromDB(limit: pageSize, offset: offset)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.canLoadMorePages = false
                    }
                }
            }, receiveValue: { [weak self] newStops in
                DispatchQueue.main.async {
                    if newStops.isEmpty {
                        self?.canLoadMorePages = false
                    } else {
                        self?.stops.append(contentsOf: newStops)
                    }
                }
            })
            .store(in: &cancellables)
    }
}
