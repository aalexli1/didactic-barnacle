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