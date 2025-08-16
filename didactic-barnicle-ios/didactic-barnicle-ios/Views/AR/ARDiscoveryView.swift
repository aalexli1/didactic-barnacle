import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import AVFoundation

struct ARDiscoveryView: View {
    @StateObject private var viewModel = ARDiscoveryViewModel()
    @EnvironmentObject var arSessionManager: ARSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var treasureService: TreasureService
    
    @State private var showingTreasureDetail = false
    @State private var selectedTreasure: Treasure?
    @State private var radarAngle: Double = 0
    @State private var proximityLevel: ProximityLevel = .far
    @State private var audioPlayer: AVAudioPlayer?
    
    enum ProximityLevel {
        case far, medium, near, veryNear
        
        var color: Color {
            switch self {
            case .far: return .blue
            case .medium: return .yellow
            case .near: return .orange
            case .veryNear: return .red
            }
        }
        
        var pulseSpeed: Double {
            switch self {
            case .far: return 2.0
            case .medium: return 1.5
            case .near: return 1.0
            case .veryNear: return 0.5
            }
        }
        
        var message: String {
            switch self {
            case .far: return "Cold... Keep searching"
            case .medium: return "Getting warmer..."
            case .near: return "Hot! Very close!"
            case .veryNear: return "Burning! Look around!"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // AR Camera View
            ARDiscoveryViewRepresentable(
                arSessionManager: arSessionManager,
                onTreasureFound: handleTreasureFound
            )
            .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                // Top Status Bar
                HStack {
                    // Back Button
                    Button(action: { /* Dismiss */ }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    // Status Info
                    VStack(alignment: .trailing) {
                        Label("\(viewModel.nearbyTreasures.count) nearby", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "location.fill")
                            Text(proximityLevel.message)
                        }
                        .font(.caption2)
                        .foregroundColor(proximityLevel.color)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
                
                // AR Radar Scanner
                ARRadarView(
                    treasures: viewModel.nearbyTreasures,
                    userLocation: locationManager.location ?? CLLocation(),
                    radarAngle: $radarAngle
                )
                .frame(width: 150, height: 150)
                .padding()
                
                // Distance Indicator
                if let nearestTreasure = viewModel.nearestTreasure {
                    ARProximityIndicator(
                        treasure: nearestTreasure,
                        distance: viewModel.distanceToNearest,
                        proximityLevel: proximityLevel
                    )
                    .padding()
                }
                
                // Bottom Controls
                HStack(spacing: 30) {
                    // Toggle Sound
                    Button(action: toggleSound) {
                        Image(systemName: viewModel.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    // Scanner Mode
                    Button(action: toggleScannerMode) {
                        Image(systemName: viewModel.scannerMode ? "qrcode.viewfinder" : "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    // Hint
                    Button(action: showHint) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
            }
            
            // Scanner Overlay
            if viewModel.scannerMode {
                ScannerOverlay()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startDiscovery()
        }
        .onDisappear {
            stopDiscovery()
        }
        .sheet(item: $selectedTreasure) { treasure in
            TreasureDetailView(treasure: treasure, onCollect: collectTreasure)
        }
        .onReceive(NotificationCenter.default.publisher(for: .treasureDiscovered)) { notification in
            if let treasure = notification.userInfo?["treasure"] as? Treasure {
                handleTreasureFound(treasure)
            }
        }
    }
    
    private func startDiscovery() {
        viewModel.startScanning()
        animateRadar()
        startProximityTracking()
    }
    
    private func stopDiscovery() {
        viewModel.stopScanning()
        audioPlayer?.stop()
    }
    
    private func animateRadar() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            radarAngle = 360
        }
    }
    
    private func startProximityTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateProximity()
        }
    }
    
    private func updateProximity() {
        guard let nearest = viewModel.nearestTreasure else { return }
        
        let distance = viewModel.distanceToNearest
        
        // Update proximity level
        if distance < 5 {
            proximityLevel = .veryNear
        } else if distance < 15 {
            proximityLevel = .near
        } else if distance < 30 {
            proximityLevel = .medium
        } else {
            proximityLevel = .far
        }
        
        // Play proximity sound
        if viewModel.soundEnabled {
            playProximitySound()
        }
        
        // Haptic feedback for very close
        if proximityLevel == .veryNear {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
        }
    }
    
    private func playProximitySound() {
        // Play beep sound based on proximity
        let frequency = proximityLevel.pulseSpeed
        
        // Create and play system sound
        AudioServicesPlaySystemSound(1103) // Beep sound
    }
    
    private func toggleSound() {
        viewModel.soundEnabled.toggle()
    }
    
    private func toggleScannerMode() {
        viewModel.scannerMode.toggle()
    }
    
    private func showHint() {
        if let nearest = viewModel.nearestTreasure,
           let hint = nearest.hint {
            // Show hint alert
        }
    }
    
    private func handleTreasureFound(_ treasure: Treasure) {
        selectedTreasure = treasure
        showingTreasureDetail = true
        
        // Play success sound
        AudioServicesPlaySystemSound(1025) // Success sound
        
        // Heavy haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred()
    }
    
    private func collectTreasure(_ treasure: Treasure) {
        viewModel.collectTreasure(treasure)
    }
}

// MARK: - AR Discovery View Representable
struct ARDiscoveryViewRepresentable: UIViewRepresentable {
    let arSessionManager: ARSessionManager
    let onTreasureFound: (Treasure) -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        arSessionManager.arView = arView
        
        // Add tap gesture for treasure interaction
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        context.coordinator.onTreasureFound = onTreasureFound
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var arView: ARView?
        var onTreasureFound: ((Treasure) -> Void)?
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            let results = arView.hitTest(location)
            
            if let firstResult = results.first {
                // Check if hit entity is a treasure
                // Trigger onTreasureFound if it is
            }
        }
    }
}

// MARK: - AR Radar View
struct ARRadarView: View {
    let treasures: [Treasure]
    let userLocation: CLLocation
    @Binding var radarAngle: Double
    
    var body: some View {
        ZStack {
            // Radar Background
            Circle()
                .fill(Color.black.opacity(0.8))
            
            // Radar Rings
            ForEach(1...3, id: \.self) { ring in
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    .scaleEffect(CGFloat(ring) * 0.33)
            }
            
            // Radar Sweep
            RadarSweep()
                .rotationEffect(.degrees(radarAngle))
            
            // Treasure Dots
            ForEach(treasures) { treasure in
                TreasureDot(treasure: treasure, userLocation: userLocation)
            }
            
            // Center User Dot
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.green, lineWidth: 2))
    }
}

struct RadarSweep: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x, y: 0))
            }
            .stroke(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 2
            )
        }
    }
}

struct TreasureDot: View {
    let treasure: Treasure
    let userLocation: CLLocation
    
    var position: CGPoint {
        // Calculate relative position on radar
        let treasureLocation = CLLocation(
            latitude: treasure.location.latitude,
            longitude: treasure.location.longitude
        )
        let distance = userLocation.distance(from: treasureLocation)
        let bearing = userLocation.bearing(to: treasureLocation)
        
        // Convert to radar coordinates (max radius 75 points, max distance 100 meters)
        let normalizedDistance = min(distance / 100, 1.0)
        let radarDistance = normalizedDistance * 65
        
        let x = radarDistance * sin(bearing * .pi / 180)
        let y = -radarDistance * cos(bearing * .pi / 180)
        
        return CGPoint(x: 75 + x, y: 75 + y)
    }
    
    var body: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 6, height: 6)
            .position(position)
            .opacity(0.8)
    }
}

// MARK: - Scanner Overlay
struct ScannerOverlay: View {
    @State private var scanLineOffset: CGFloat = -100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Corner brackets
                VStack {
                    HStack {
                        ScannerCorner(rotation: 0)
                        Spacer()
                        ScannerCorner(rotation: 90)
                    }
                    Spacer()
                    HStack {
                        ScannerCorner(rotation: -90)
                        Spacer()
                        ScannerCorner(rotation: 180)
                    }
                }
                .padding(40)
                
                // Scanning line
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 2)
                    .offset(y: scanLineOffset)
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                            scanLineOffset = 100
                        }
                    }
            }
        }
    }
}

struct ScannerCorner: View {
    let rotation: Double
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.green, lineWidth: 3)
        .frame(width: 20, height: 20)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Proximity Indicator
struct ARProximityIndicator: View {
    let treasure: Treasure
    let distance: Double
    let proximityLevel: ARDiscoveryView.ProximityLevel
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(proximityLevel.color)
                
                Text("\(Int(distance))m away")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Proximity Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 10)
                        .cornerRadius(5)
                    
                    Rectangle()
                        .fill(proximityLevel.color)
                        .frame(width: geometry.size.width * (1 - min(distance / 100, 1)), height: 10)
                        .cornerRadius(5)
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: proximityLevel.pulseSpeed).repeatForever(), value: isPulsing)
                }
            }
            .frame(height: 10)
            
            Text(proximityLevel.message)
                .font(.caption)
                .foregroundColor(proximityLevel.color)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Treasure Detail View
struct TreasureDetailView: View {
    let treasure: Treasure
    let onCollect: (Treasure) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showingConfetti = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow, Color.orange],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(showingConfetti ? 1.2 : 1.0)
                        .animation(.spring(), value: showingConfetti)
                    
                    if showingConfetti {
                        ConfettiView()
                    }
                }
                
                Text("Treasure Discovered!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(treasure.title)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                if let message = treasure.message {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                
                HStack {
                    Label("\(treasure.points) points", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Label(treasure.difficulty.rawValue.capitalized, systemImage: "flag.fill")
                        .font(.headline)
                        .foregroundColor(Color(treasure.difficulty.color))
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    onCollect(treasure)
                    dismiss()
                }) {
                    Text("Collect Treasure")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareTreasure()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring().delay(0.5)) {
                showingConfetti = true
            }
        }
    }
    
    private func shareTreasure() {
        // Share functionality
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let rotation: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(x: piece.x, y: piece.y)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity.animation(.easeOut(duration: 2))
                    ))
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                color: [.red, .blue, .green, .yellow, .orange, .purple].randomElement()!,
                x: CGFloat.random(in: -100...300),
                y: CGFloat.random(in: -200...200),
                size: CGFloat.random(in: 5...15),
                rotation: Double.random(in: 0...360)
            )
            confettiPieces.append(piece)
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confettiPieces.removeAll()
        }
    }
}

// MARK: - View Model
class ARDiscoveryViewModel: ObservableObject {
    @Published var nearbyTreasures: [Treasure] = []
    @Published var nearestTreasure: Treasure?
    @Published var distanceToNearest: Double = 0
    @Published var soundEnabled = true
    @Published var scannerMode = false
    
    func startScanning() {
        // Start scanning for treasures
        loadNearbyTreasures()
    }
    
    func stopScanning() {
        // Stop scanning
    }
    
    func collectTreasure(_ treasure: Treasure) {
        // Mark treasure as collected
    }
    
    private func loadNearbyTreasures() {
        // Load mock treasures for now
        nearbyTreasures = Treasure.mockTreasures()
        nearestTreasure = nearbyTreasures.first
        distanceToNearest = Double.random(in: 10...50)
    }
}

// MARK: - CLLocation Extensions
extension CLLocation {
    func bearing(to location: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        let lat2 = location.coordinate.latitude.degreesToRadians
        let lon2 = location.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let bearing = atan2(y, x).radiansToDegrees
        
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}