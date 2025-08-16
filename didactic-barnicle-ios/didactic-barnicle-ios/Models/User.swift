import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
    let avatarURL: String?
    var level: Int
    var experience: Int
    let joinedAt: Date
    var friends: [User]
    var settings: UserSettings
    
    var treasuresCreated: Int
    var treasuresFound: Int
    var points: Int
    var bio: String?
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        avatarURL: String? = nil,
        level: Int = 1,
        experience: Int = 0,
        joinedAt: Date = Date(),
        friends: [User] = [],
        settings: UserSettings = UserSettings(),
        treasuresCreated: Int = 0,
        treasuresFound: Int = 0,
        points: Int = 0,
        bio: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
        self.level = level
        self.experience = experience
        self.joinedAt = joinedAt
        self.friends = friends
        self.settings = settings
        self.treasuresCreated = treasuresCreated
        self.treasuresFound = treasuresFound
        self.points = points
        self.bio = bio
        self.isActive = isActive
    }
}

struct UserSettings: Codable {
    var notificationsEnabled: Bool
    var locationSharingEnabled: Bool
    var privateProfile: Bool
    var discoveryRadius: Double
    
    init(
        notificationsEnabled: Bool = true,
        locationSharingEnabled: Bool = true,
        privateProfile: Bool = false,
        discoveryRadius: Double = 1000.0
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.locationSharingEnabled = locationSharingEnabled
        self.privateProfile = privateProfile
        self.discoveryRadius = discoveryRadius
    }
}