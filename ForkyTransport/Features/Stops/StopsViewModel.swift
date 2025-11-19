import Foundation
import Combine

@MainActor
final class StopsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var stops: [StopData] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let apiService: EMTAPIServiceProtocol
    private let dbService: DatabaseServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: EMTAPIServiceProtocol, dbService: DatabaseServiceProtocol) {
        self.apiService = apiService
        self.dbService = dbService
    }
    
    // MARK: - Public Methods
    
    func fetchStops() {
        isLoading = true
        errorMessage = nil
        
        // Chain of publishers:
        // 1. Get token from the database.
        // 2. Use the token to call the API for stops.
        dbService.getToken()
            .flatMap { [weak self] token -> AnyPublisher<[StopData], Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                guard let token = token else { return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher() }
                
                // Use the fetched token to make the API call
                return self.apiService.getAllStops(accessToken: token.accessToken)
            }
            .receive(on: DispatchQueue.main) // Switch to the main thread for UI updates
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al cargar las paradas: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] stops in
                self?.stops = stops
            })
            .store(in: &cancellables)
    }
}