import Foundation
import ARKit
import RealityKit
import Combine
import CoreLocation

class ARSessionManager: NSObject, ObservableObject {
    let session = ARSession()
    var arView: ARView?
    
    @Published var isSessionRunning = false
    @Published var sessionError: Error?
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var detectedAnchors: [ARAnchor] = []
    @Published var placedTreasures: [TreasureAnchor] = []
    @Published var nearbyTreasures: [Treasure] = []
    @Published var isPlacingTreasure = false
    @Published var previewEntity: Entity?
    @Published var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private var cancellables = Set<AnyCancellable>()
    private var treasureEntities: [UUID: Entity] = [:]
    private var proximityTimer: Timer?
    
    override init() {
        super.init()
        session.delegate = self
        hapticFeedback.prepare()
    }
    
    func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.frameSemantics = .personSegmentationWithDepth
        
        // Enable collaborative session for shared AR experiences
        configuration.isCollaborationEnabled = ARWorldTrackingConfiguration.supportsUserFaceTracking
        
        // Enable image tracking if needed
        if let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources", 
            bundle: nil
        ) {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 10
        }
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isSessionRunning = true
        startProximityTracking()
    }
    
    func pauseSession() {
        session.pause()
        isSessionRunning = false
        stopProximityTracking()
    }
    
    func resetSession() {
        let configuration = session.configuration ?? ARWorldTrackingConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        detectedAnchors.removeAll()
        placedTreasures.removeAll()
        treasureEntities.removeAll()
    }
    
    func addAnchor(at transform: simd_float4x4) {
        let anchor = ARAnchor(transform: transform)
        session.add(anchor: anchor)
    }
    
    func removeAnchor(_ anchor: ARAnchor) {
        session.remove(anchor: anchor)
    }
    
    // MARK: - Treasure Placement
    
    func placeTreasure(_ treasure: Treasure, at position: SIMD3<Float>) -> TreasureAnchor? {
        guard let arView = arView else { return nil }
        
        let transform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(position.x, position.y, position.z, 1)
        )
        
        let anchor = TreasureAnchor(treasure: treasure, transform: transform)
        session.add(anchor: anchor)
        
        // Create visual entity for the treasure
        if let entity = createTreasureEntity(for: treasure) {
            entity.position = position
            treasureEntities[treasure.id] = entity
            arView.scene.addAnchor(entity as! HasAnchoring)
            
            // Add placement animation
            animateTreasurePlacement(entity)
            
            // Haptic feedback
            hapticFeedback.impactOccurred()
        }
        
        placedTreasures.append(anchor)
        return anchor
    }
    
    func startTreasurePlacement(for treasure: Treasure) {
        isPlacingTreasure = true
        
        // Create preview entity
        if let entity = createTreasureEntity(for: treasure) {
            entity.scale *= 1.2 // Make preview slightly larger
            previewEntity = entity
            
            // Add transparency for preview
            if var modelComponent = entity.components[ModelComponent.self] {
                modelComponent.materials = modelComponent.materials.map { material in
                    var updatedMaterial = material
                    if var physicallyBased = updatedMaterial as? PhysicallyBasedMaterial {
                        physicallyBased.baseColor.tint.alpha = 0.7
                        return physicallyBased
                    }
                    return updatedMaterial
                }
                entity.components[ModelComponent.self] = modelComponent
            }
        }
    }
    
    func cancelTreasurePlacement() {
        isPlacingTreasure = false
        previewEntity = nil
    }
    
    func confirmTreasurePlacement(_ treasure: Treasure) -> Bool {
        guard let previewEntity = previewEntity else { return false }
        
        let position = previewEntity.position
        if let anchor = placeTreasure(treasure, at: position) {
            isPlacingTreasure = false
            self.previewEntity = nil
            return true
        }
        
        return false
    }
    
    // MARK: - Treasure Discovery
    
    private func startProximityTracking() {
        proximityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkTreasureProximity()
        }
    }
    
    private func stopProximityTracking() {
        proximityTimer?.invalidate()
        proximityTimer = nil
    }
    
    private func checkTreasureProximity() {
        guard let frame = session.currentFrame else { return }
        
        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                         cameraTransform.columns.3.y,
                                         cameraTransform.columns.3.z)
        
        for anchor in placedTreasures {
            let anchorPosition = SIMD3<Float>(anchor.transform.columns.3.x,
                                             anchor.transform.columns.3.y,
                                             anchor.transform.columns.3.z)
            
            let distance = simd_distance(cameraPosition, anchorPosition)
            
            // Update treasure visibility based on distance
            if let entity = treasureEntities[anchor.treasure.id] {
                updateTreasureVisibility(entity, distance: distance)
                
                // Trigger discovery if very close
                if distance < 2.0 { // Within 2 meters
                    discoverTreasure(anchor.treasure)
                }
            }
        }
    }
    
    private func updateTreasureVisibility(_ entity: Entity, distance: Float) {
        // Pulse effect for nearby treasures
        if distance < 10.0 {
            let intensity = 1.0 - (distance / 10.0)
            let scale = 1.0 + (0.1 * sin(Date().timeIntervalSince1970 * 2) * intensity)
            entity.scale = SIMD3<Float>(repeating: Float(scale))
        }
    }
    
    private func discoverTreasure(_ treasure: Treasure) {
        // Prevent multiple discoveries
        guard !treasure.discoveries.contains(where: { $0.userId == getCurrentUserId() }) else { return }
        
        // Trigger discovery haptics
        let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpact.prepare()
        heavyImpact.impactOccurred()
        
        // Notify discovery
        NotificationCenter.default.post(
            name: .treasureDiscovered,
            object: nil,
            userInfo: ["treasure": treasure]
        )
    }
    
    // MARK: - Entity Creation
    
    private func createTreasureEntity(for treasure: Treasure) -> Entity? {
        let entity = ModelEntity()
        
        // Create mesh based on treasure type
        let mesh: MeshResource
        let material: Material
        
        switch treasure.arObject.type {
        case "chest":
            mesh = MeshResource.generateBox(size: 0.3)
            material = SimpleMaterial(color: UIColor(hex: treasure.arObject.color) ?? .yellow, isMetallic: true)
        case "gem":
            mesh = MeshResource.generateSphere(radius: 0.15)
            material = SimpleMaterial(color: UIColor(hex: treasure.arObject.color) ?? .cyan, isMetallic: true)
        case "artifact":
            mesh = MeshResource.generateCylinder(height: 0.3, radius: 0.1)
            material = SimpleMaterial(color: UIColor(hex: treasure.arObject.color) ?? .brown, isMetallic: false)
        case "dragon_egg":
            mesh = MeshResource.generateSphere(radius: 0.2)
            material = SimpleMaterial(color: UIColor(hex: treasure.arObject.color) ?? .purple, isMetallic: true)
        default:
            mesh = MeshResource.generateBox(size: 0.2)
            material = SimpleMaterial(color: .systemYellow, isMetallic: true)
        }
        
        entity.model = ModelComponent(mesh: mesh, materials: [material])
        entity.scale = SIMD3<Float>(repeating: treasure.arObject.scale)
        
        // Add collision for interaction
        entity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(repeating: 0.3))])
        
        // Add physics for floating effect
        entity.physicsBody = PhysicsBodyComponent(
            massProperties: .init(mass: 0.1),
            material: nil,
            mode: .kinematic
        )
        
        return entity
    }
    
    private func animateTreasurePlacement(_ entity: Entity) {
        // Scale up animation
        entity.scale = SIMD3<Float>(repeating: 0.01)
        
        var transform = entity.transform
        transform.scale = SIMD3<Float>(repeating: 1.0)
        
        entity.move(to: transform, relativeTo: entity.parent, duration: 0.5, timingFunction: .easeOut)
        
        // Add particle effect
        addPlacementParticles(at: entity.position)
    }
    
    private func addPlacementParticles(at position: SIMD3<Float>) {
        // Particle effects would be added here using RealityKit's particle system
    }
    
    // Helper function to get current user ID
    private func getCurrentUserId() -> UUID {
        // This would normally fetch from UserDefaults or authentication service
        return UUID()
    }
}

// MARK: - ARSessionDelegate
extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionError = error
        isSessionRunning = false
        
        // Handle session errors
        if let arError = error as? ARError {
            switch arError.code {
            case .cameraUnauthorized:
                print("Camera access not authorized")
            case .sensorUnavailable:
                print("Required sensor unavailable")
            case .worldTrackingFailed:
                print("World tracking failed")
            default:
                print("AR Session error: \(error.localizedDescription)")
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        trackingState = camera.trackingState
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        detectedAnchors.append(contentsOf: anchors)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        detectedAnchors.removeAll { anchor in
            anchors.contains { $0.identifier == anchor.identifier }
        }
    }
}

// MARK: - ARSessionObserver
extension ARSessionManager: ARSessionObserver {
    func sessionWasInterrupted(_ session: ARSession) {
        isSessionRunning = false
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        resetSession()
        isSessionRunning = true
    }
}