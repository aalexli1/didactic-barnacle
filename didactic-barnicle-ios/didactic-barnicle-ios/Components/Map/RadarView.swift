import SwiftUI
import CoreLocation

struct RadarView: View {
    let treasures: [Treasure]
    let userLocation: CLLocation?
    let heading: CLHeading?
    @State private var radarRotation: Double = 0
    
    private let radarRadius: CGFloat = 100
    private let maxDistance: CLLocationDistance = 500 // 500 meters max range
    
    var body: some View {
        ZStack {
            // Radar background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.3),
                            Color.green.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: radarRadius
                    )
                )
                .frame(width: radarRadius * 2, height: radarRadius * 2)
            
            // Radar rings
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: radarRadius * 2 * scale,
                        height: radarRadius * 2 * scale
                    )
            }
            
            // Scanning line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green,
                            Color.green.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: radarRadius)
                .offset(y: -radarRadius / 2)
                .rotationEffect(.degrees(radarRotation))
                .animation(
                    Animation.linear(duration: 4)
                        .repeatForever(autoreverses: false),
                    value: radarRotation
                )
            
            // North indicator
            VStack(spacing: 0) {
                Image(systemName: "location.north.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text("N")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            .offset(y: -radarRadius - 20)
            .rotationEffect(.degrees(-(heading?.magneticHeading ?? 0)))
            
            // Treasure blips
            if let userLocation = userLocation {
                ForEach(treasures.prefix(10)) { treasure in
                    if let blipPosition = calculateBlipPosition(
                        treasure: treasure,
                        userLocation: userLocation
                    ) {
                        TreasureBlip(treasure: treasure)
                            .position(x: blipPosition.x, y: blipPosition.y)
                    }
                }
            }
            
            // User position (center)
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .frame(width: radarRadius * 2, height: radarRadius * 2)
        .onAppear {
            radarRotation = 360
        }
    }
    
    private func calculateBlipPosition(
        treasure: Treasure,
        userLocation: CLLocation
    ) -> CGPoint? {
        let treasureLocation = CLLocation(
            latitude: treasure.location.latitude,
            longitude: treasure.location.longitude
        )
        
        let distance = userLocation.distance(from: treasureLocation)
        
        // Skip if too far
        if distance > maxDistance {
            return nil
        }
        
        // Calculate bearing
        let bearing = calculateBearing(
            from: userLocation.coordinate,
            to: treasure.location
        )
        
        // Adjust for device heading
        let adjustedBearing = bearing - (heading?.magneticHeading ?? 0)
        
        // Convert to radians
        let radians = adjustedBearing * .pi / 180
        
        // Calculate position on radar
        let normalizedDistance = min(distance / maxDistance, 1.0)
        let x = radarRadius + sin(radians) * radarRadius * normalizedDistance
        let y = radarRadius - cos(radians) * radarRadius * normalizedDistance
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateBearing(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        var bearing = atan2(x, y) * 180 / .pi
        if bearing < 0 {
            bearing += 360
        }
        
        return bearing
    }
}

struct TreasureBlip: View {
    let treasure: Treasure
    @State private var isBlinking = false
    
    private var blipColor: Color {
        switch treasure.difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .legendary: return .purple
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(blipColor)
                .frame(width: 8, height: 8)
                .opacity(isBlinking ? 0.3 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: isBlinking
                )
            
            Circle()
                .stroke(blipColor, lineWidth: 1)
                .frame(width: 12, height: 12)
                .opacity(isBlinking ? 0 : 0.6)
                .scaleEffect(isBlinking ? 1.5 : 1.0)
                .animation(
                    Animation.easeOut(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isBlinking
                )
        }
        .onAppear {
            isBlinking = true
        }
    }
}