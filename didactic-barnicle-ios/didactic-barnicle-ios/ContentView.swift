//
//  ContentView.swift
//  didactic-barnicle-ios
//
//  Created by Alex Li on 8/14/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var arSessionManager: ARSessionManager
    
    @State private var showLaunchScreen = true
    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: "OnboardingComplete")
    @State private var permissionsGranted = UserDefaults.standard.bool(forKey: "PermissionsGranted")
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreen()
                    .transition(.opacity)
            } else if !isOnboardingComplete {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .onChange(of: isOnboardingComplete) { newValue in
                        if newValue {
                            UserDefaults.standard.set(true, forKey: "OnboardingComplete")
                        }
                    }
            } else if !permissionsGranted {
                PermissionsView(permissionsGranted: $permissionsGranted)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .onChange(of: permissionsGranted) { newValue in
                        if newValue {
                            UserDefaults.standard.set(true, forKey: "PermissionsGranted")
                        }
                    }
            } else {
                MainTabView()
                    .environmentObject(appCoordinator)
                    .environmentObject(locationManager)
                    .environmentObject(arSessionManager)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppCoordinator())
        .environmentObject(LocationManager())
        .environmentObject(ARSessionManager())
}
