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
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        apiService.login(email: email, password: password)
            .flatMap { token in
                self.dbService.saveToken(token)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] _ in
                self?.router.navigateTo(.home)
            })
            .store(in: &cancellables)
    }
}
