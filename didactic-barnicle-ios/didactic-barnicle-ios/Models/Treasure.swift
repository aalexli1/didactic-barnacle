import Foundation
import CoreLocation

struct Treasure: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
    let points: Int
    let difficulty: Difficulty
    let hint: String
    let arModelName: String
    let imageURL: String?
    
    enum Difficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case legendary = "Legendary"
        
        var color: String {
            switch self {
            case .easy: return "green"
            case .medium: return "yellow"
            case .hard: return "orange"
            case .legendary: return "purple"
            }
        }
        
        var points: Int {
            switch self {
            case .easy: return 10
            case .medium: return 25
            case .hard: return 50
            case .legendary: return 100
            }
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // Mock data for testing
    static func mockTreasures() -> [Treasure] {
        [
            Treasure(
                id: "1",
                name: "Golden Chest",
                description: "A mysterious golden chest hidden in the park",
                latitude: 37.7749,
                longitude: -122.4194,
                points: 50,
                difficulty: .medium,
                hint: "Look near the fountain",
                arModelName: "chest.usdz",
                imageURL: nil
            ),
            Treasure(
                id: "2",
                name: "Ancient Artifact",
                description: "An ancient artifact from a lost civilization",
                latitude: 37.7751,
                longitude: -122.4180,
                points: 100,
                difficulty: .hard,
                hint: "Under the old oak tree",
                arModelName: "artifact.usdz",
                imageURL: nil
            ),
            Treasure(
                id: "3",
                name: "Crystal Gem",
                description: "A sparkling crystal gem with magical properties",
                latitude: 37.7745,
                longitude: -122.4189,
                points: 25,
                difficulty: .easy,
                hint: "Near the playground",
                arModelName: "gem.usdz",
                imageURL: nil
            ),
            Treasure(
                id: "4",
                name: "Pirate's Bounty",
                description: "Lost treasure from a pirate ship",
                latitude: 37.7755,
                longitude: -122.4200,
                points: 75,
                difficulty: .medium,
                hint: "By the water's edge",
                arModelName: "bounty.usdz",
                imageURL: nil
            ),
            Treasure(
                id: "5",
                name: "Dragon's Egg",
                description: "A legendary dragon egg of immense power",
                latitude: 37.7760,
                longitude: -122.4175,
                points: 200,
                difficulty: .legendary,
                hint: "At the highest point",
                arModelName: "dragon_egg.usdz",
                imageURL: nil
            )
        ]
    }
}