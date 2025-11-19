import SwiftUI

@main
struct ForkyTransportApp: App {
    
    // MARK: - Core Services
    private let apiService: EMTAPIServiceProtocol
    private let dbService: DatabaseServiceProtocol? // Now optional
    
    // MARK: - App State
    @StateObject private var router = Router()
    
    init() {
        print("[App] App Initializing...")
        // Initialize the concrete services
        self.apiService = EMTAPIService()
        self.dbService = DatabaseService() // Use the failable init
        print("[App] > apiService initialized.")
        print("[App] > dbService initialized: \(dbService != nil)")
    }
    
    var body: some Scene {
        WindowGroup {
            // Check if critical services were initialized correctly.
            if let dbService = dbService {
                // If services are OK, show the main app view.
                VStack { // Use a VStack to easily add a log
                    Text("").onAppear { print("[App] Main app body appeared with valid services.") }
                    switch router.currentScreen {
                    case .login:
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
            } else {
                // If a service failed to init, show a critical error view.
                ErrorView(
                    title: "Error Crítico",
                    message: "La base de datos no pudo ser inicializada. La aplicación no puede continuar. Por favor, reinstala la aplicación."
                )
            }
        }
    }
}