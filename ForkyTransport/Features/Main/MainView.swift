import SwiftUI

struct MainView: View {
    
    // MARK: - Dependencies
    let apiService: EMTAPIServiceProtocol
    let dbService: DatabaseServiceProtocol
    
    init(apiService: EMTAPIServiceProtocol, dbService: DatabaseServiceProtocol) {
        self.apiService = apiService
        self.dbService = dbService
        
        // Configure TabBar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            // Create the StopsView with its ViewModel, injecting the dependencies.
            let stopsViewModel = StopsViewModel(apiService: apiService, dbService: dbService)
            StopsView(viewModel: stopsViewModel)
                .tabItem {
                    Label("Paradas", systemImage: "bus.fill")
                }
            
            SchedulesView()
                .tabItem {
                    Label("Horarios", systemImage: "clock")
                }
            
            MapView()
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }
            
            FaresView()
                .tabItem {
                    Label("Tarifas", systemImage: "eurosign.circle")
                }
        }
    }
}