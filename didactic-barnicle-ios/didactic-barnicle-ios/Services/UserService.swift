import Foundation
import Combine

class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUser: UserProfile?
    @Published var totalPoints: Int = 0
    @Published var level: Int = 1
    @Published var achievements: [Achievement] = []
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadUserProfile()
        loadAchievements()
    }
    
    private func loadUserProfile() {
        if let data = userDefaults.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
            totalPoints = profile.totalPoints
            level = profile.level
        } else {
            // Create default profile
            createDefaultProfile()
        }
    }
    
    private func createDefaultProfile() {
        let defaultProfile = UserProfile(
            id: UUID().uuidString,
            username: "Explorer\(Int.random(in: 1000...9999))",
            email: "",
            totalPoints: 0,
            level: 1,
            avatarImageName: "person.circle.fill",
            joinDate: Date(),
            treasuresCollected: 0
        )
        currentUser = defaultProfile
        saveUserProfile()
    }
    
    private func saveUserProfile() {
        guard let user = currentUser else { return }
        
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "userProfile")
        }
    }
    
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: "achievements"),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = saved
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            userDefaults.set(data, forKey: "achievements")
        }
    }
    
    func updateProfile(username: String? = nil, email: String? = nil, avatarImageName: String? = nil) {
        guard var user = currentUser else { return }
        
        if let username = username {
            user.username = username
        }
        if let email = email {
            user.email = email
        }
        if let avatarImageName = avatarImageName {
            user.avatarImageName = avatarImageName
        }
        
        currentUser = user
        saveUserProfile()
    }
    
    func addPoints(_ points: Int) {
        totalPoints += points
        
        if var user = currentUser {
            user.totalPoints = totalPoints
            user.level = calculateLevel(from: totalPoints)
            currentUser = user
            saveUserProfile()
        }
        
        checkForNewAchievements()
    }
    
    func incrementTreasuresCollected() {
        if var user = currentUser {
            user.treasuresCollected += 1
            currentUser = user
            saveUserProfile()
        }
        
        checkForNewAchievements()
    }
    
    private func calculateLevel(from points: Int) -> Int {
        // Simple level calculation: every 100 points = 1 level
        return max(1, (points / 100) + 1)
    }
    
    private func checkForNewAchievements() {
        // Check for point-based achievements
        if totalPoints >= 100 && !hasAchievement(id: "first_100_points") {
            unlockAchievement(Achievement(
                id: "first_100_points",
                title: "Centurion",
                description: "Earned 100 points",
                iconName: "star.fill",
                unlockedDate: Date()
            ))
        }
        
        // Check for treasure-based achievements
        if let user = currentUser {
            if user.treasuresCollected >= 1 && !hasAchievement(id: "first_treasure") {
                unlockAchievement(Achievement(
                    id: "first_treasure",
                    title: "First Discovery",
                    description: "Found your first treasure",
                    iconName: "sparkles",
                    unlockedDate: Date()
                ))
            }
            
            if user.treasuresCollected >= 10 && !hasAchievement(id: "treasure_hunter") {
                unlockAchievement(Achievement(
                    id: "treasure_hunter",
                    title: "Treasure Hunter",
                    description: "Collected 10 treasures",
                    iconName: "trophy.fill",
                    unlockedDate: Date()
                ))
            }
        }
    }
    
    private func hasAchievement(id: String) -> Bool {
        achievements.contains { $0.id == id }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        achievements.append(achievement)
        saveAchievements()
        
        // Could trigger a notification here
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievement
        )
    }
    
    func resetProgress() {
        totalPoints = 0
        level = 1
        achievements = []
        createDefaultProfile()
        saveAchievements()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Achievement Model
struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let unlockedDate: Date
}