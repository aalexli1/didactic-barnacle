import Foundation
import ARKit

class TreasureAnchor: ARAnchor {
    let treasure: Treasure
    
    init(treasure: Treasure, transform: simd_float4x4) {
        self.treasure = treasure
        super.init(name: treasure.id.uuidString, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        // This would need to decode the treasure from the anchor name or other stored data
        self.treasure = Treasure(
            id: UUID(uuidString: anchor.name ?? "") ?? UUID(),
            creatorId: UUID(),
            title: "Unknown Treasure",
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        // Decode treasure data
        guard let treasureData = aDecoder.decodeObject(forKey: "treasureData") as? Data,
              let treasure = try? JSONDecoder().decode(Treasure.self, from: treasureData) else {
            return nil
        }
        
        self.treasure = treasure
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        // Encode treasure data
        if let treasureData = try? JSONEncoder().encode(treasure) {
            aCoder.encode(treasureData, forKey: "treasureData")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let treasureDiscovered = Notification.Name("treasureDiscovered")
    static let treasurePlaced = Notification.Name("treasurePlaced")
    static let treasureRemoved = Notification.Name("treasureRemoved")
}

// MARK: - UIColor Extension for Hex Colors
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        
        if length == 6 {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else if length == 8 {
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
}