import Foundation
import CoreLocation
import ARKit

enum TreasureType: String, Codable, CaseIterable {
    case standard = "standard"
    case premium = "premium"
    case special = "special"
    case event = "event"
}

enum Visibility: String, Codable, CaseIterable {
    case publicVisibility = "public"
    case friends = "friends"
    case privateVisibility = "private"
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .legendary: return "purple"
        }
    }
    
    var basePoints: Int {
        switch self {
        case .easy: return 10
        case .medium: return 25
        case .hard: return 50
        case .legendary: return 100
        }
    }
}

struct Treasure: Codable, Identifiable {
    let id: UUID
    let creatorId: UUID
    var title: String
    var description: String?
    var message: String?
    let location: CLLocationCoordinate2D
    let altitude: Double
    var arAnchorData: Data?
    let type: TreasureType
    var mediaURL: String?
    let visibility: Visibility
    let difficulty: Difficulty
    var hint: String?
    var points: Int
    var maxDiscoveries: Int?
    var isActive: Bool
    let createdAt: Date
    let expiresAt: Date?
    var discoveries: [Discovery]
    
    var arObject: ARObjectConfig
    
    init(
        id: UUID = UUID(),
        creatorId: UUID,
        title: String,
        description: String? = nil,
        message: String? = nil,
        location: CLLocationCoordinate2D,
        altitude: Double = 0,
        arAnchorData: Data? = nil,
        type: TreasureType = .standard,
        mediaURL: String? = nil,
        visibility: Visibility = .publicVisibility,
        difficulty: Difficulty = .medium,
        hint: String? = nil,
        points: Int = 10,
        maxDiscoveries: Int? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        discoveries: [Discovery] = [],
        arObject: ARObjectConfig = ARObjectConfig()
    ) {
        self.id = id
        self.creatorId = creatorId
        self.title = title
        self.description = description
        self.message = message
        self.location = location
        self.altitude = altitude
        self.arAnchorData = arAnchorData
        self.type = type
        self.mediaURL = mediaURL
        self.visibility = visibility
        self.difficulty = difficulty
        self.hint = hint
        self.points = points
        self.maxDiscoveries = maxDiscoveries
        self.isActive = isActive
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.discoveries = discoveries
        self.arObject = arObject
    }
    
    var coordinate: CLLocationCoordinate2D {
        location
    }
    
    var locationCL: CLLocation {
        CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
    
    static func mockTreasures() -> [Treasure] {
        let mockUserId = UUID()
        return [
            Treasure(
                id: UUID(),
                creatorId: mockUserId,
                title: "Golden Chest",
                description: "A mysterious golden chest hidden in the park",
                message: "Congratulations! You've found the golden chest!",
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                type: .premium,
                visibility: .publicVisibility,
                difficulty: .medium,
                hint: "Look near the fountain",
                points: 50,
                arObject: ARObjectConfig(type: "chest", modelUrl: "chest.usdz", color: "#FFD700", scale: 1.0)
            ),
            Treasure(
                id: UUID(),
                creatorId: mockUserId,
                title: "Ancient Artifact",
                description: "An ancient artifact from a lost civilization",
                message: "Amazing! You've discovered an ancient artifact!",
                location: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4180),
                type: .special,
                visibility: .publicVisibility,
                difficulty: .hard,
                hint: "Under the old oak tree",
                points: 100,
                arObject: ARObjectConfig(type: "artifact", modelUrl: "artifact.usdz", color: "#8B4513", scale: 1.2)
            ),
            Treasure(
                id: UUID(),
                creatorId: mockUserId,
                title: "Crystal Gem",
                description: "A sparkling crystal gem with magical properties",
                message: "Wonderful! You've found the crystal gem!",
                location: CLLocationCoordinate2D(latitude: 37.7745, longitude: -122.4189),
                type: .standard,
                visibility: .publicVisibility,
                difficulty: .easy,
                hint: "Near the playground",
                points: 25,
                arObject: ARObjectConfig(type: "gem", modelUrl: "gem.usdz", color: "#00CED1", scale: 0.8)
            ),
            Treasure(
                id: UUID(),
                creatorId: mockUserId,
                title: "Pirate's Bounty",
                description: "Lost treasure from a pirate ship",
                message: "Ahoy! You've found the pirate's bounty!",
                location: CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4200),
                type: .premium,
                visibility: .publicVisibility,
                difficulty: .medium,
                hint: "By the water's edge",
                points: 75,
                arObject: ARObjectConfig(type: "bounty", modelUrl: "bounty.usdz", color: "#C0C0C0", scale: 1.1)
            ),
            Treasure(
                id: UUID(),
                creatorId: mockUserId,
                title: "Dragon's Egg",
                description: "A legendary dragon egg of immense power",
                message: "Incredible! You've discovered the legendary dragon egg!",
                location: CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4175),
                type: .event,
                visibility: .publicVisibility,
                difficulty: .legendary,
                hint: "At the highest point",
                points: 200,
                arObject: ARObjectConfig(type: "dragon_egg", modelUrl: "dragon_egg.usdz", color: "#9400D3", scale: 1.5)
            )
        ]
    }
}

struct ARObjectConfig: Codable {
    var type: String
    var modelUrl: String?
    var color: String
    var scale: Float
    
    init(
        type: String = "default",
        modelUrl: String? = nil,
        color: String = "#FFD700",
        scale: Float = 1.0
    ) {
        self.type = type
        self.modelUrl = modelUrl
        self.color = color
        self.scale = scale
    }
}

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}