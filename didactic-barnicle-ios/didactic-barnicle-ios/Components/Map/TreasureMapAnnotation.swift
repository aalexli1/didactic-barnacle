import SwiftUI
import MapKit

struct TreasureMapAnnotation: View {
    let treasure: Treasure
    let distance: CLLocationDistance?
    @State private var showDetail = false
    @State private var animationScale: CGFloat = 1.0
    
    private var rarity: TreasureRarity {
        switch treasure.difficulty {
        case .easy:
            return .common
        case .medium:
            return .uncommon
        case .hard:
            return .rare
        case .legendary:
            return .legendary
        }
    }
    
    var body: some View {
        ZStack {
            // Pulsing ring animation
            Circle()
                .fill(rarity.color.opacity(0.3))
                .frame(width: 60, height: 60)
                .scaleEffect(animationScale)
                .opacity(2 - animationScale)
                .animation(
                    Animation.easeOut(duration: 2)
                        .repeatForever(autoreverses: false),
                    value: animationScale
                )
            
            // Main treasure marker
            VStack(spacing: 0) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(rarity.color.gradient)
                        .frame(width: 40, height: 40)
                    
                    // Icon based on treasure type
                    Image(systemName: treasureIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: rarity.color.opacity(0.6), radius: 8)
                
                // Distance indicator
                if let distance = distance {
                    Text(formatDistance(distance))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .offset(y: 4)
                }
            }
        }
        .onAppear {
            animationScale = 1.5
        }
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            TreasurePreviewCard(treasure: treasure, distance: distance)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var treasureIcon: String {
        switch treasure.type {
        case .standard:
            return "star.fill"
        case .premium:
            return "crown.fill"
        case .special:
            return "sparkles"
        case .event:
            return "gift.fill"
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

enum TreasureRarity {
    case common, uncommon, rare, legendary
    
    var color: Color {
        switch self {
        case .common:
            return .green
        case .uncommon:
            return .blue
        case .rare:
            return .purple
        case .legendary:
            return .orange
        }
    }
}