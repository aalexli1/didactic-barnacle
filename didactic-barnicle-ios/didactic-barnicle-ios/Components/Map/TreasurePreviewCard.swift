import SwiftUI
import MapKit

struct TreasurePreviewCard: View {
    let treasure: Treasure
    let distance: CLLocationDistance?
    @Environment(\.dismiss) var dismiss
    @State private var navigateToAR = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(treasure.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Label(treasure.difficulty.rawValue.capitalized, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(difficultyColor)
                        
                        if let distance = distance {
                            Label(formatDistance(distance), systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Points badge
                VStack {
                    Text("\(treasure.points)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.2))
                )
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Description
            if let description = treasure.description {
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
            }
            
            // Hint
            if let hint = treasure.hint {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text(hint)
                        .font(.callout)
                        .italic()
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
                .padding(.horizontal)
            }
            
            // Stats
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("\(treasure.discoveries.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Found")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let maxDiscoveries = treasure.maxDiscoveries {
                    VStack {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(.green)
                        Text("\(maxDiscoveries - treasure.discoveries.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let expiresAt = treasure.expiresAt {
                    VStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.red)
                        Text(timeRemaining(until: expiresAt))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Expires")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: startNavigation) {
                    Label("Navigate", systemImage: "location.north.line.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { navigateToAR = true }) {
                    Label("AR View", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $navigateToAR) {
            ARCameraView(targetTreasure: treasure)
        }
    }
    
    private var difficultyColor: Color {
        switch treasure.difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .legendary: return .purple
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
    
    private func timeRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }
    
    private func startNavigation() {
        // Open in Maps app
        let placemark = MKPlacemark(coordinate: treasure.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = treasure.title
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
        dismiss()
    }
}