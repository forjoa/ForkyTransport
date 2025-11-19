import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let apiService: EMTAPIServiceProtocol
    private let dbService: DatabaseServiceProtocol
    private let router: Router
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        apiService: EMTAPIServiceProtocol,
        dbService: DatabaseServiceProtocol,
        router: Router
    ) {
        self.apiService = apiService
        self.dbService = dbService
        self.router = router
        
        // For development, pre-fill credentials
        #if DEBUG
        self.email = "joaquin_trujillo@icloud.com"
        self.password = "PanConPollo04"
        #endif
    }
    
    func login() {
        print("[LoginViewModel] login() called.")
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        apiService.login(email: email, password: password)
            .flatMap { [weak self] token -> AnyPublisher<Void, Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                print("[LoginViewModel] > Login API call successful. Token received. Now saving to DB.")
                return self.dbService.saveToken(token)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                    print("[LoginViewModel] > Login process FAILED: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] _ in
                print("[LoginViewModel] > Token saved to DB successfully. Navigating to home.")
                self?.router.navigateTo(.home)
            })
            .store(in: &cancellables)
    }
}
