import Foundation
import RealityKit
import ARKit
import SwiftUI

// MARK: - AR Particle System
class ARParticleSystem {
    
    static func createDiscoveryParticles() -> Entity {
        let particleEntity = Entity()
        
        // Create multiple particle emitters for a sparkle effect
        for _ in 0..<20 {
            let particle = createSparkleParticle()
            particleEntity.addChild(particle)
        }
        
        return particleEntity
    }
    
    static func createPlacementParticles() -> Entity {
        let particleEntity = Entity()
        
        // Create ring expansion effect
        let ring = createExpandingRing()
        particleEntity.addChild(ring)
        
        // Add sparkles
        for _ in 0..<10 {
            let sparkle = createSparkleParticle()
            particleEntity.addChild(sparkle)
        }
        
        return particleEntity
    }
    
    private static func createSparkleParticle() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.01)
        let material = SimpleMaterial(color: .yellow, isMetallic: true)
        let particle = ModelEntity(mesh: mesh, materials: [material])
        
        // Random position around center
        let angle = Float.random(in: 0...(2 * .pi))
        let radius = Float.random(in: 0.1...0.3)
        particle.position = SIMD3<Float>(
            radius * cos(angle),
            Float.random(in: -0.1...0.1),
            radius * sin(angle)
        )
        
        // Animate upward and fade
        var transform = particle.transform
        transform.translation.y += 0.5
        particle.move(to: transform, relativeTo: particle.parent, duration: 2.0)
        
        return particle
    }
    
    private static func createExpandingRing() -> ModelEntity {
        let mesh = MeshResource.generateTorus(meanRadius: 0.2, tubeRadius: 0.01)
        let material = SimpleMaterial(color: .green, isMetallic: true)
        let ring = ModelEntity(mesh: mesh, materials: [material])
        
        // Start small and expand
        ring.scale = SIMD3<Float>(repeating: 0.1)
        
        var transform = ring.transform
        transform.scale = SIMD3<Float>(repeating: 2.0)
        ring.move(to: transform, relativeTo: ring.parent, duration: 1.0)
        
        return ring
    }
}

// MARK: - AR Animation Helpers
extension Entity {
    
    func addFloatingAnimation(amplitude: Float = 0.05, period: TimeInterval = 2.0) {
        // Create floating effect
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let time = Date().timeIntervalSince1970
            let offset = amplitude * sin(Float(time * 2 * .pi / period))
            self.position.y = self.position.y + offset
        }
    }
    
    func addRotationAnimation(speed: Float = 1.0) {
        // Continuous rotation
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            self.transform.rotation *= simd_quatf(angle: speed * 0.016, axis: SIMD3<Float>(0, 1, 0))
        }
    }
    
    func addPulseAnimation(minScale: Float = 0.9, maxScale: Float = 1.1, period: TimeInterval = 1.0) {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let time = Date().timeIntervalSince1970
            let scale = minScale + (maxScale - minScale) * (1 + sin(Float(time * 2 * .pi / period))) / 2
            self.scale = SIMD3<Float>(repeating: scale)
        }
    }
    
    func addSparkleEffect() {
        // Add random sparkle particles
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            let sparkle = ARParticleSystem.createSparkleParticle()
            self.addChild(sparkle)
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                sparkle.removeFromParent()
            }
        }
    }
}

// MARK: - AR Visual Effects
struct ARVisualEffects {
    
    static func createTreasureGlow(color: UIColor = .yellow) -> Entity {
        let glowEntity = Entity()
        
        // Create multiple spheres with different sizes for glow effect
        let glowLayers = [
            (radius: Float(0.35), alpha: Float(0.1)),
            (radius: Float(0.30), alpha: Float(0.2)),
            (radius: Float(0.25), alpha: Float(0.3))
        ]
        
        for layer in glowLayers {
            let mesh = MeshResource.generateSphere(radius: layer.radius)
            var material = SimpleMaterial(color: color.withAlphaComponent(CGFloat(layer.alpha)), isMetallic: false)
            material.roughness = .float(1.0)
            
            let sphere = ModelEntity(mesh: mesh, materials: [material])
            glowEntity.addChild(sphere)
        }
        
        return glowEntity
    }
    
    static func createDistanceIndicator(distance: Float) -> Entity {
        let indicatorEntity = Entity()
        
        // Create arrow pointing to treasure
        let arrowMesh = MeshResource.generateCone(height: 0.2, radius: 0.05)
        let color = distanceToColor(distance)
        let material = SimpleMaterial(color: color, isMetallic: true)
        
        let arrow = ModelEntity(mesh: arrowMesh, materials: [material])
        arrow.position.y = 0.5
        
        // Add distance text (would need TextMesh in actual implementation)
        indicatorEntity.addChild(arrow)
        
        return indicatorEntity
    }
    
    private static func distanceToColor(_ distance: Float) -> UIColor {
        if distance < 5 {
            return .red
        } else if distance < 15 {
            return .orange
        } else if distance < 30 {
            return .yellow
        } else {
            return .blue
        }
    }
    
    static func createCompass() -> Entity {
        let compassEntity = Entity()
        
        // Create compass ring
        let ringMesh = MeshResource.generateTorus(meanRadius: 0.3, tubeRadius: 0.02)
        let ringMaterial = SimpleMaterial(color: .white, isMetallic: true)
        let ring = ModelEntity(mesh: ringMesh, materials: [ringMaterial])
        
        // Create cardinal direction markers
        let directions = ["N", "E", "S", "W"]
        let angles: [Float] = [0, .pi/2, .pi, 3*.pi/2]
        
        for (index, direction) in directions.enumerated() {
            let marker = createDirectionMarker(text: direction)
            let angle = angles[index]
            marker.position = SIMD3<Float>(
                0.35 * sin(angle),
                0,
                0.35 * cos(angle)
            )
            compassEntity.addChild(marker)
        }
        
        compassEntity.addChild(ring)
        return compassEntity
    }
    
    private static func createDirectionMarker(text: String) -> ModelEntity {
        // Simplified marker - in real implementation would use TextMesh
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.05, 0.05, 0.01))
        let material = SimpleMaterial(color: .white, isMetallic: false)
        return ModelEntity(mesh: mesh, materials: [material])
    }
}

// MARK: - AR Sound Effects
class ARSoundEffects {
    static let shared = ARSoundEffects()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        preloadSounds()
    }
    
    private func preloadSounds() {
        // Preload common sound effects
        let soundNames = [
            "treasure_discovered",
            "treasure_placed",
            "proximity_beep",
            "radar_ping"
        ]
        
        for soundName in soundNames {
            if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[soundName] = player
                } catch {
                    print("Failed to load sound: \(soundName)")
                }
            }
        }
    }
    
    func playSound(_ name: String, volume: Float = 1.0) {
        if let player = audioPlayers[name] {
            player.volume = volume
            player.play()
        }
    }
    
    func playProximityBeep(distance: Float) {
        let volume = max(0.1, 1.0 - (distance / 50.0))
        playSound("proximity_beep", volume: volume)
    }
    
    func playDiscoverySound() {
        playSound("treasure_discovered")
    }
    
    func playPlacementSound() {
        playSound("treasure_placed")
    }
}

// MARK: - AR Treasure Emoji Factory
struct ARTreasureEmojiFactory {
    
    static func createEmojiEntity(emoji: String, scale: Float = 1.0) -> ModelEntity {
        // Create a 3D representation of an emoji
        // In a real implementation, this would create a 3D text mesh with the emoji
        
        // For now, create a colored sphere based on emoji
        let color = emojiToColor(emoji)
        let mesh = MeshResource.generateSphere(radius: 0.15 * scale)
        let material = SimpleMaterial(color: color, isMetallic: true)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Add effects based on emoji type
        switch emoji {
        case "💎":
            entity.addSparkleEffect()
            entity.addRotationAnimation(speed: 0.5)
        case "🎁":
            entity.addPulseAnimation()
        case "⭐":
            entity.addRotationAnimation(speed: 1.0)
            entity.addSparkleEffect()
        case "🏆":
            entity.addFloatingAnimation()
        default:
            entity.addFloatingAnimation(amplitude: 0.02)
        }
        
        return entity
    }
    
    private static func emojiToColor(_ emoji: String) -> UIColor {
        switch emoji {
        case "🎁": return .red
        case "💎": return .cyan
        case "🏆": return .yellow
        case "⭐": return .orange
        case "🔮": return .purple
        case "💰": return .green
        case "🗝": return .gray
        case "👑": return .yellow
        default: return .blue
        }
    }
    
    static func createAnimated3DModel(type: String) -> ModelEntity? {
        switch type {
        case "chest":
            return createChestModel()
        case "gem":
            return createGemModel()
        case "artifact":
            return createArtifactModel()
        default:
            return nil
        }
    }
    
    private static func createChestModel() -> ModelEntity {
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.2, 0.2))
        let material = SimpleMaterial(color: .brown, isMetallic: false)
        let chest = ModelEntity(mesh: mesh, materials: [material])
        
        // Add gold trim
        let trimMesh = MeshResource.generateBox(size: SIMD3<Float>(0.32, 0.22, 0.22))
        let trimMaterial = SimpleMaterial(color: .yellow, isMetallic: true)
        let trim = ModelEntity(mesh: trimMesh, materials: [trimMaterial])
        trim.scale = SIMD3<Float>(1.0, 0.9, 0.9)
        
        chest.addChild(trim)
        chest.addFloatingAnimation()
        
        return chest
    }
    
    private static func createGemModel() -> ModelEntity {
        // Create octahedron-like gem shape using multiple pyramids
        let topMesh = MeshResource.generateCone(height: 0.15, radius: 0.1)
        let material = SimpleMaterial(color: .cyan, isMetallic: true)
        
        let topPart = ModelEntity(mesh: topMesh, materials: [material])
        let bottomPart = ModelEntity(mesh: topMesh, materials: [material])
        bottomPart.transform.rotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
        
        let gem = Entity()
        gem.addChild(topPart)
        gem.addChild(bottomPart)
        
        gem.addRotationAnimation(speed: 0.5)
        gem.addSparkleEffect()
        
        return gem as! ModelEntity
    }
    
    private static func createArtifactModel() -> ModelEntity {
        let mesh = MeshResource.generateCylinder(height: 0.3, radius: 0.08)
        let material = SimpleMaterial(color: .brown, isMetallic: false)
        let artifact = ModelEntity(mesh: mesh, materials: [material])
        
        // Add decorative rings
        for i in 0...2 {
            let ringMesh = MeshResource.generateTorus(meanRadius: 0.09, tubeRadius: 0.01)
            let ringMaterial = SimpleMaterial(color: .yellow, isMetallic: true)
            let ring = ModelEntity(mesh: ringMesh, materials: [ringMaterial])
            ring.position.y = -0.1 + Float(i) * 0.1
            artifact.addChild(ring)
        }
        
        artifact.addFloatingAnimation()
        artifact.addRotationAnimation(speed: 0.2)
        
        return artifact
    }
}

// MARK: - AR Helper Extensions
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}