import Foundation

struct UserProfile: Codable {
    var id: String
    var username: String
    var email: String
    var totalPoints: Int
    var level: Int
    var avatarImageName: String
    let joinDate: Date
    var treasuresCollected: Int
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinDate)
    }
    
    var nextLevelPoints: Int {
        level * 100
    }
    
    var currentLevelProgress: Double {
        let currentLevelStart = (level - 1) * 100
        let currentLevelEnd = level * 100
        let progress = Double(totalPoints - currentLevelStart) / Double(currentLevelEnd - currentLevelStart)
        return min(max(progress, 0), 1)
    }
}