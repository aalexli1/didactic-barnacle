import SwiftUI
import ARKit
import RealityKit

struct ARCameraView: View {
    @EnvironmentObject var arSessionManager: ARSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var isARActive = false
    @State private var showingPermissionAlert = false
    @State private var detectedTreasures: [Treasure] = []
    @State private var showingTreasureFound = false
    @State private var foundTreasure: Treasure?
    
    var body: some View {
        NavigationView {
            ZStack {
                ARViewContainer(
                    arSessionManager: arSessionManager,
                    detectedTreasures: $detectedTreasures,
                    onTreasureFound: handleTreasureFound
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("AR Hunt Mode")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(isARActive ? "Scanning for treasures..." : "AR Inactive")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    if !detectedTreasures.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(detectedTreasures) { treasure in
                                    TreasureRadarView(treasure: treasure)
                                }
                            }
                            .padding()
                        }
                        .background(Color.black.opacity(0.7))
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: toggleARSession) {
                            Image(systemName: isARActive ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: resetARSession) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                }
            }
            .navigationTitle("AR Hunt")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkCameraPermission()
            }
            .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable camera access to use AR features.")
            }
            .sheet(isPresented: $showingTreasureFound) {
                if let treasure = foundTreasure {
                    TreasureFoundView(treasure: treasure)
                }
            }
        }
    }
    
    private func toggleARSession() {
        if isARActive {
            arSessionManager.pauseSession()
        } else {
            arSessionManager.startSession()
        }
        isARActive.toggle()
    }
    
    private func resetARSession() {
        arSessionManager.resetSession()
        detectedTreasures.removeAll()
    }
    
    private func handleTreasureFound(_ treasure: Treasure) {
        foundTreasure = treasure
        showingTreasureFound = true
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isARActive = true
            arSessionManager.startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isARActive = true
                        arSessionManager.startSession()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        default:
            showingPermissionAlert = true
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arSessionManager: ARSessionManager
    @Binding var detectedTreasures: [Treasure]
    let onTreasureFound: (Treasure) -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        arSessionManager.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
}

struct TreasureRadarView: View {
    let treasure: Treasure
    
    var body: some View {
        VStack {
            Image(systemName: "star.circle")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.yellow)
            Text(treasure.name)
                .font(.caption)
                .foregroundColor(.white)
            Text("\(Int(treasure.distanceFromUser ?? 0))m")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

struct TreasureFoundView: View {
    let treasure: Treasure
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.yellow)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                            .offset(x: 50, y: 50)
                    )
                
                Text("Treasure Found!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(treasure.name)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("You've discovered a hidden treasure!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Collect Treasure")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Congratulations!")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ARCameraView()
        .environmentObject(ARSessionManager())
        .environmentObject(LocationManager())
}