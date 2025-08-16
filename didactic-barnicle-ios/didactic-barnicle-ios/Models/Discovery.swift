import Foundation

enum ReactionType: String, Codable, CaseIterable {
    case like = "like"
    case love = "love"
    case wow = "wow"
    case funny = "funny"
    case cool = "cool"
}

struct Discovery: Codable, Identifiable {
    let id: UUID
    let treasureId: UUID
    let userId: UUID
    let discoveredAt: Date
    var photoURL: String?
    var comment: String?
    var reactionType: ReactionType?
    var pointsEarned: Int
    var timeToFind: Int?
    var distanceFromTreasure: Float?
    
    init(
        id: UUID = UUID(),
        treasureId: UUID,
        userId: UUID,
        discoveredAt: Date = Date(),
        photoURL: String? = nil,
        comment: String? = nil,
        reactionType: ReactionType? = nil,
        pointsEarned: Int = 0,
        timeToFind: Int? = nil,
        distanceFromTreasure: Float? = nil
    ) {
        self.id = id
        self.treasureId = treasureId
        self.userId = userId
        self.discoveredAt = discoveredAt
        self.photoURL = photoURL
        self.comment = comment
        self.reactionType = reactionType
        self.pointsEarned = pointsEarned
        self.timeToFind = timeToFind
        self.distanceFromTreasure = distanceFromTreasure
    }
}