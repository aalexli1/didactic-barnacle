import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    
    enum LeaderboardPeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case allTime = "All Time"
        
        var apiValue: String {
            switch self {
            case .daily: return "daily"
            case .weekly: return "weekly"
            case .monthly: return "monthly"
            case .allTime: return "all_time"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                periodPicker
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let userRank = viewModel.userRank {
                                userRankCard(rank: userRank)
                            }
                            
                            leaderboardList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadLeaderboard(period: selectedPeriod.apiValue)
            }
        }
    }
    
    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: selectedPeriod) { newPeriod in
            viewModel.loadLeaderboard(period: newPeriod.apiValue)
        }
    }
    
    private func userRankCard(rank: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("#\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.userPoints)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var leaderboardList: some View {
        VStack(spacing: 8) {
            ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, rank: index + 1)
            }
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            rankBadge
            
            if let avatarUrl = entry.user.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.user.username)
                    .fontWeight(.medium)
                Text("Level \(entry.user.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.points)")
                    .fontWeight(.bold)
                Text("points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor)
                .frame(width: 32, height: 32)
            
            if rank <= 3 {
                Image(systemName: rankIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            } else {
                Text("\(rank)")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray3)
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "star.fill"
        case 3: return "star.fill"
        default: return ""
        }
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var userRank: Int?
    @Published var userPoints: Int = 0
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiClient = APIClient.shared
    private let authService = AuthenticationService.shared
    
    func loadLeaderboard(period: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                guard let token = authService.authToken else {
                    throw AuthError.tokenExpired
                }
                
                let response = try await apiClient.getLeaderboard(token: token.accessToken, period: period)
                
                await MainActor.run {
                    self.leaderboard = response.leaderboard
                    self.userRank = response.userRank
                    self.userPoints = response.userPoints ?? 0
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

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let user: LeaderboardUser
    let points: Int
    let treasuresFound: Int
    let treasuresCreated: Int
    let streakDays: Int
}

struct LeaderboardUser: Codable {
    let id: String
    let username: String
    let avatarUrl: String?
    let level: Int
}

struct LeaderboardResponse: Codable {
    let leaderboard: [LeaderboardEntry]
    let userRank: Int?
    let userPoints: Int?
    let period: String
}