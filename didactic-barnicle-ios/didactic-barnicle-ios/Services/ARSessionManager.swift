import Foundation
import ARKit
import Combine

class ARSessionManager: NSObject, ObservableObject {
    let session = ARSession()
    
    @Published var isSessionRunning = false
    @Published var sessionError: Error?
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var detectedAnchors: [ARAnchor] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable image tracking if needed
        if let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources", 
            bundle: nil
        ) {
            configuration.detectionImages = referenceImages
        }
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isSessionRunning = true
    }
    
    func pauseSession() {
        session.pause()
        isSessionRunning = false
    }
    
    func resetSession() {
        let configuration = session.configuration ?? ARWorldTrackingConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        detectedAnchors.removeAll()
    }
    
    func addAnchor(at transform: simd_float4x4) {
        let anchor = ARAnchor(transform: transform)
        session.add(anchor: anchor)
    }
    
    func removeAnchor(_ anchor: ARAnchor) {
        session.remove(anchor: anchor)
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