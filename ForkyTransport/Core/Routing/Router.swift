import Foundation
import SwiftUI
import Combine

/// An enum to define all possible navigation destinations in the app.
enum Screen {
    case login
    case home
}

/// The Router is a global, observable object responsible for managing the app's navigation state.
/// Views can change the state of the app by calling methods on the router.
final class Router: ObservableObject {
    @Published var currentScreen: Screen = .login
    
    func navigateTo(_ screen: Screen) {
        self.currentScreen = screen
    }
    
    func navigateToRoot() {
        self.currentScreen = .login
    }
}
