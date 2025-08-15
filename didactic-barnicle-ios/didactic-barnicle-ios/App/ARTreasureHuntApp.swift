import SwiftUI

@main
struct ARTreasureHuntApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var arSessionManager = ARSessionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .environmentObject(locationManager)
                .environmentObject(arSessionManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Request permissions on app launch
        locationManager.requestLocationPermission()
    }
}