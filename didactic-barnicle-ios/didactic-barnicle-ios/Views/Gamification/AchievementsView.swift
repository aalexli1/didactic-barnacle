import SwiftUI

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var selectedCategory: AchievementCategory = .all
    
    enum AchievementCategory: String, CaseIterable {
        case all = "All"
        case discovery = "Discovery"
        case creation = "Creation"
        case social = "Social"
        case exploration = "Exploration"
        case special = "Special"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let stats = viewModel.stats {
                    statsHeader(stats: stats)
                }
                
                categoryPicker
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadAchievements()
            }
        }
    }
    
    private func statsHeader(stats: AchievementStats) -> some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(stats.completed)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Unlocked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(stats.total)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(stats.points)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var filteredAchievements: [Achievement] {
        if selectedCategory == .all {
            return viewModel.achievements
        } else {
            return viewModel.achievements.filter { $0.category == selectedCategory.rawValue.lowercased() }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.completed ? rarityColor : Color(.systemGray5))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon ?? "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(achievement.completed ? .white : .gray)
            }
            
            Text(achievement.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if achievement.completed {
                Text("\(achievement.points) pts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                ProgressView(value: Double(achievement.progress), total: Double(achievement.requirement))
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
                
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(achievement.completed ? 1.0 : 0.7)
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case "legendary": return .purple
        case "epic": return .orange
        case "rare": return .blue
        case "uncommon": return .green
        default: return .gray
        }
    }
}

class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var stats: AchievementStats?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiClient = APIClient.shared
    private let authService = AuthenticationService.shared
    
    func loadAchievements() {
        isLoading = true
        error = nil
        
        Task {
            do {
                guard let token = authService.authToken else {
                    throw AuthError.tokenExpired
                }
                
                let response = try await apiClient.getAchievements(token: token.accessToken)
                
                await MainActor.run {
                    self.achievements = response.achievements
                    self.stats = response.stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let icon: String?
    let points: Int
    let rarity: String
    let progress: Int
    let requirement: Int
    let completed: Bool
    let completedAt: Date?
}

struct AchievementStats: Codable {
    let total: Int
    let completed: Int
    let points: Int
}

struct AchievementsResponse: Codable {
    let achievements: [Achievement]
    let stats: AchievementStats
}

extension APIClient {
    func getLeaderboard(token: String, period: String) async throws -> LeaderboardResponse {
        let url = URL(string: "\(baseURL)/activity/leaderboard/\(period)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(LeaderboardResponse.self, from: data)
    }
    
    func getAchievements(token: String) async throws -> AchievementsResponse {
        let url = URL(string: "\(baseURL)/activity/achievements")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AchievementsResponse.self, from: data)
    }
}