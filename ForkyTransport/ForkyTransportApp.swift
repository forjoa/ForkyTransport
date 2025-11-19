import SwiftUI

@main
struct ForkyTransportApp: App {
    
    // MARK: - Core Services
    // These are the single instances of our services that the app will use.
    private let apiService: EMTAPIServiceProtocol
    private let dbService: DatabaseServiceProtocol
    
    // MARK: - App State
    @StateObject private var router = Router()
    
    init() {
        do {
            self.dbService = try DatabaseService()
            self.apiService = try EMTAPIService()
        } catch {
            // If the database fails to initialize, it's a fatal error.
            fatalError("Failed to initialize DatabaseService: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // The RootView listens to the router and presents the correct screen.
            // This is the central point of navigation logic.
            switch router.currentScreen {
            case .login:
                // We create and inject the ViewModel with its dependencies here.
                let loginViewModel = LoginViewModel(
                    apiService: apiService,
                    dbService: dbService,
                    router: router
                )
                LoginView(viewModel: loginViewModel)
                
            case .home:
                MainView(apiService: apiService, dbService: dbService)
            }
        }
    }
}
