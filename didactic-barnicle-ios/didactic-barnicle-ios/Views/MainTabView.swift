import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(0)
            
            ARCameraView()
                .tabItem {
                    Label("AR Hunt", systemImage: "camera.viewfinder")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}