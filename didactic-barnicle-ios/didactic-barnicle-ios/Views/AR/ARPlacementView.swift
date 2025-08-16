import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARPlacementView: View {
    @StateObject private var viewModel = ARPlacementViewModel()
    @EnvironmentObject var arSessionManager: ARSessionManager
    @EnvironmentObject var treasureService: TreasureService
    @State private var selectedTreasureType: TreasureType = .standard
    @State private var selectedEmoji: String = "🎁"
    @State private var treasureMessage: String = ""
    @State private var showingPlacementControls = false
    @State private var placementPosition: CGPoint = .zero
    @State private var showingSuccessAlert = false
    @State private var isPlacingMode = false
    
    let availableEmojis = ["🎁", "💎", "🏆", "⭐", "🔮", "💰", "🗝", "👑", "🎯", "🎨", "🎭", "🎪"]
    
    var body: some View {
        ZStack {
            // AR View
            ARViewRepresentable(
                arSessionManager: arSessionManager,
                placementPosition: $placementPosition,
                isPlacingMode: $isPlacingMode
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture(coordinateSpace: .local) { location in
                if isPlacingMode {
                    placementPosition = location
                    showingPlacementControls = true
                }
            }
            
            // UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button("Cancel") {
                        dismissView()
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Place Treasure")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(trackingStatusText)
                            .font(.caption)
                            .foregroundColor(trackingStatusColor)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
                
                // Treasure Selection
                if !isPlacingMode {
                    VStack(spacing: 20) {
                        // Emoji Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(availableEmojis, id: \.self) { emoji in
                                    Button(action: {
                                        selectedEmoji = emoji
                                        viewModel.updatePreviewTreasure(emoji: emoji)
                                    }) {
                                        Text(emoji)
                                            .font(.system(size: 40))
                                            .padding()
                                            .background(
                                                Circle()
                                                    .fill(selectedEmoji == emoji ? Color.blue : Color.black.opacity(0.5))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Message Input
                        VStack(alignment: .leading) {
                            Text("Treasure Message")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            TextField("Enter a message for finders...", text: $treasureMessage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        // Type Selection
                        Picker("Treasure Type", selection: $selectedTreasureType) {
                            ForEach(TreasureType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Start Placement Button
                        Button(action: startPlacement) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Start Placement")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                }
                
                // Placement Controls
                if showingPlacementControls {
                    VStack(spacing: 15) {
                        Text("Tap to adjust position")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            Button(action: cancelPlacement) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Cancel")
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: confirmPlacement) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Place Here")
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
            
            // Center Crosshair for placement
            if isPlacingMode {
                Image(systemName: "plus.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(radius: 5)
            }
        }
        .alert("Treasure Placed!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismissView()
            }
        } message: {
            Text("Your treasure has been successfully placed and is ready to be discovered!")
        }
    }
    
    private var trackingStatusText: String {
        switch arSessionManager.trackingState {
        case .normal:
            return "Tracking Normal"
        case .limited(.excessiveMotion):
            return "Slow down movement"
        case .limited(.insufficientFeatures):
            return "Point at textured surface"
        case .limited(.initializing):
            return "Initializing..."
        case .limited(.relocalizing):
            return "Relocalizing..."
        case .notAvailable:
            return "AR Not Available"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var trackingStatusColor: Color {
        switch arSessionManager.trackingState {
        case .normal:
            return .green
        case .limited:
            return .yellow
        case .notAvailable:
            return .red
        @unknown default:
            return .gray
        }
    }
    
    private func startPlacement() {
        isPlacingMode = true
        arSessionManager.startTreasurePlacement(for: createTreasure())
    }
    
    private func cancelPlacement() {
        showingPlacementControls = false
        isPlacingMode = false
        arSessionManager.cancelTreasurePlacement()
    }
    
    private func confirmPlacement() {
        let treasure = createTreasure()
        if arSessionManager.confirmTreasurePlacement(treasure) {
            // Save treasure to backend
            treasureService.createTreasure(treasure) { success in
                if success {
                    showingSuccessAlert = true
                }
            }
            showingPlacementControls = false
            isPlacingMode = false
        }
    }
    
    private func createTreasure() -> Treasure {
        return Treasure(
            creatorId: UUID(), // Would get from auth service
            title: "Mystery \(selectedEmoji)",
            message: treasureMessage.isEmpty ? nil : treasureMessage,
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Will be set from GPS
            type: selectedTreasureType,
            visibility: .publicVisibility,
            difficulty: .medium,
            points: 50,
            arObject: ARObjectConfig(
                type: "emoji",
                color: "#FFD700",
                scale: 1.0
            )
        )
    }
    
    private func dismissView() {
        // Dismiss view logic
    }
}

// MARK: - AR View Representable
struct ARViewRepresentable: UIViewRepresentable {
    let arSessionManager: ARSessionManager
    @Binding var placementPosition: CGPoint
    @Binding var isPlacingMode: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        arSessionManager.arView = arView
        
        // Setup coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Add gesture recognizers
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if isPlacingMode, let previewEntity = arSessionManager.previewEntity {
            // Update preview position based on touch
            let results = uiView.raycast(
                from: placementPosition,
                allowing: .estimatedPlane,
                alignment: .any
            )
            
            if let firstResult = results.first {
                previewEntity.position = SIMD3<Float>(
                    firstResult.worldTransform.columns.3.x,
                    firstResult.worldTransform.columns.3.y,
                    firstResult.worldTransform.columns.3.z
                )
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var arView: ARView?
    }
}

// MARK: - View Model
class ARPlacementViewModel: ObservableObject {
    @Published var previewTreasure: Treasure?
    @Published var isPlacing = false
    
    func updatePreviewTreasure(emoji: String) {
        // Update preview with selected emoji
    }
}