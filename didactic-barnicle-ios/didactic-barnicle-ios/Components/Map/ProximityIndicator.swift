import SwiftUI
import CoreLocation

struct ProximityIndicator: View {
    let distance: CLLocationDistance
    let treasureName: String
    @State private var pulseAnimation = false
    
    private var proximityLevel: ProximityLevel {
        switch distance {
        case 0..<10:
            return .hot
        case 10..<30:
            return .warmer
        case 30..<60:
            return .warm
        case 60..<100:
            return .cool
        case 100..<200:
            return .cold
        default:
            return .freezing
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Distance text
            Text(formatDistance(distance))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(proximityLevel.color)
            
            // Proximity feedback
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index < proximityLevel.barCount ? proximityLevel.color : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 30)
                        .scaleEffect(y: pulseAnimation && index < proximityLevel.barCount ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .delay(Double(index) * 0.1)
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
            }
            
            // Temperature indicator
            HStack(spacing: 4) {
                Image(systemName: proximityLevel.icon)
                    .font(.title2)
                    .foregroundColor(proximityLevel.color)
                
                Text(proximityLevel.text)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(proximityLevel.color)
            }
            
            // Treasure name
            Text("to \(treasureName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(proximityLevel.color.opacity(0.5), lineWidth: 2)
                )
        )
        .shadow(color: proximityLevel.color.opacity(0.3), radius: 10)
        .onAppear {
            pulseAnimation = true
        }
        .onChange(of: proximityLevel) { _ in
            // Haptic feedback on proximity change
            if proximityLevel == .hot {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else if proximityLevel.barCount >= 3 {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 100 {
            return "\(Int(distance))m"
        } else if distance < 1000 {
            return "\(Int(distance / 10) * 10)m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

enum ProximityLevel {
    case hot, warmer, warm, cool, cold, freezing
    
    var color: Color {
        switch self {
        case .hot: return .red
        case .warmer: return .orange
        case .warm: return .yellow
        case .cool: return .mint
        case .cold: return .cyan
        case .freezing: return .blue
        }
    }
    
    var text: String {
        switch self {
        case .hot: return "HOT!"
        case .warmer: return "Warmer"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .cold: return "Cold"
        case .freezing: return "Freezing"
        }
    }
    
    var icon: String {
        switch self {
        case .hot: return "flame.fill"
        case .warmer: return "sun.max.fill"
        case .warm: return "sun.min.fill"
        case .cool: return "cloud.fill"
        case .cold: return "snowflake"
        case .freezing: return "snowflake.circle.fill"
        }
    }
    
    var barCount: Int {
        switch self {
        case .hot: return 5
        case .warmer: return 4
        case .warm: return 3
        case .cool: return 2
        case .cold: return 1
        case .freezing: return 0
        }
    }
}