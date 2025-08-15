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
    
    var body: some View {
        MainTabView()
            .environmentObject(appCoordinator)
            .environmentObject(locationManager)
            .environmentObject(arSessionManager)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppCoordinator())
        .environmentObject(LocationManager())
        .environmentObject(ARSessionManager())
}
