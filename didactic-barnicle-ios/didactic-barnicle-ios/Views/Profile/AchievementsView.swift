import SwiftUI

struct AchievementsView: View {
    @StateObject private var userService = UserService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressHeader
                
                if userService.achievements.isEmpty {
                    emptyState
                } else {
                    achievementsList
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("\(userService.achievements.count)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Achievements Unlocked")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(userService.achievements.count), total: 20)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Achievements Yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start hunting treasures to unlock achievements!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    private var achievementsList: some View {
        VStack(spacing: 12) {
            ForEach(userService.achievements) { achievement in
                AchievementRow(achievement: achievement)
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 30))
                .foregroundColor(.yellow)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Unlocked \(formatDate(achievement.unlockedDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}