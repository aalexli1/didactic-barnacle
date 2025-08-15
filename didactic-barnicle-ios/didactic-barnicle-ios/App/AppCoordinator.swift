import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    enum Tab {
        case map
        case arCamera
        case profile
    }
    
    enum NavigationPath {
        case treasureDetail(id: String)
        case settings
        case achievements
        case leaderboard
    }
    
    @Published var selectedTab: Tab = .map
    @Published var navigationPath = [NavigationPath]()
    @Published var isOnboarding = false
    
    init() {
        checkFirstLaunch()
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            isOnboarding = true
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        isOnboarding = false
    }
    
    func navigateTo(_ path: NavigationPath) {
        navigationPath.append(path)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func switchTab(to tab: Tab) {
        selectedTab = tab
    }
}