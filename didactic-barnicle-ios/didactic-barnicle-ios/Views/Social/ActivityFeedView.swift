import SwiftUI

struct ActivityFeedView: View {
    @StateObject private var viewModel = ActivityFeedViewModel()
    @State private var selectedActivity: ActivityItem?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading && viewModel.activities.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if viewModel.activities.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No Activity Yet",
                        message: "Connect with friends to see their treasure hunting adventures!"
                    )
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.activities) { activity in
                            ActivityCard(activity: activity, onTap: {
                                selectedActivity = activity
                            })
                        }
                        
                        if viewModel.hasMore {
                            ProgressView()
                                .onAppear {
                                    viewModel.loadMoreActivities()
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshActivities()
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
        .onAppear {
            viewModel.loadActivities()
        }
    }
}

struct ActivityCard: View {
    let activity: ActivityItem
    let onTap: () -> Void
    @State private var hasLiked = false
    @State private var likesCount = 0
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let avatarUrl = activity.user.avatarUrl {
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
                    Text(activity.user.username)
                        .fontWeight(.semibold)
                    Text(activity.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: activityIcon)
                    .foregroundColor(activityColor)
            }
            
            Text(activity.content)
                .font(.body)
                .lineLimit(3)
            
            if let treasure = activity.treasure {
                TreasurePreview(treasure: treasure)
                    .onTapGesture {
                        onTap()
                    }
            }
            
            if let challenge = activity.challenge {
                ChallengePreview(challenge: challenge)
            }
            
            HStack(spacing: 20) {
                Button(action: toggleLike) {
                    HStack(spacing: 4) {
                        Image(systemName: hasLiked ? "heart.fill" : "heart")
                            .foregroundColor(hasLiked ? .red : .gray)
                        Text("\(likesCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showingComments = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.gray)
                        Text("\(activity.commentsCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: shareActivity) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            hasLiked = activity.hasLiked
            likesCount = activity.likesCount
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(activityId: activity.id)
        }
    }
    
    private var activityIcon: String {
        switch activity.type {
        case "discovery":
            return "mappin.and.ellipse"
        case "treasure_created":
            return "plus.circle.fill"
        case "challenge_completed":
            return "trophy.fill"
        default:
            return "sparkles"
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case "discovery":
            return .blue
        case "treasure_created":
            return .green
        case "challenge_completed":
            return .orange
        default:
            return .gray
        }
    }
    
    private func toggleLike() {
        hasLiked.toggle()
        likesCount += hasLiked ? 1 : -1
        
        Task {
            await viewModel.toggleLike(for: activity.id, liked: hasLiked)
        }
    }
    
    private func shareActivity() {
        
    }
}

struct TreasurePreview: View {
    let treasure: ActivityTreasure
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(treasure.title)
                    .fontWeight(.medium)
                Text(treasure.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack {
                    Label("\(treasure.difficulty)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Label("\(treasure.points) pts", systemImage: "bitcoinsign.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct ChallengePreview: View {
    let challenge: ActivityChallenge
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.name)
                    .fontWeight(.medium)
                Label("\(challenge.difficulty)", systemImage: "flag.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            Spacer()
            Text("\(challenge.rewardPoints) pts")
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct CommentsView: View {
    let activityId: String
    @StateObject private var viewModel = CommentsViewModel()
    @State private var newComment = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: postComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                viewModel.loadComments(for: activityId)
            }
        }
    }
    
    private func postComment() {
        Task {
            await viewModel.postComment(newComment, for: activityId)
            newComment = ""
        }
    }
}

struct CommentRow: View {
    let comment: ActivityComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let avatarUrl = comment.user.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.username)
                        .fontWeight(.medium)
                        .font(.caption)
                    Text(comment.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(comment.content)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

struct ActivityDetailView: View {
    let activity: ActivityItem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                }
                .padding()
            }
            .navigationTitle("Activity Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

class ActivityFeedViewModel: ObservableObject {
    @Published var activities: [ActivityItem] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    private let pageSize = 20
    
    func loadActivities() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            
            await MainActor.run {
                self.activities = ActivityItem.mockData
                self.isLoading = false
            }
        }
    }
    
    func loadMoreActivities() {
        guard !isLoading && hasMore else { return }
        currentPage += 1
        loadActivities()
    }
    
    func refreshActivities() async {
        currentPage = 1
        activities.removeAll()
        loadActivities()
    }
    
    func toggleLike(for activityId: String, liked: Bool) async {
        
    }
}

class CommentsViewModel: ObservableObject {
    @Published var comments: [ActivityComment] = []
    @Published var isLoading = false
    
    func loadComments(for activityId: String) {
        isLoading = true
        Task {
            
            await MainActor.run {
                self.comments = ActivityComment.mockData
                self.isLoading = false
            }
        }
    }
    
    func postComment(_ content: String, for activityId: String) async {
        
    }
}

struct ActivityItem: Identifiable {
    let id: String
    let type: String
    let user: ActivityUser
    let content: String
    let treasure: ActivityTreasure?
    let challenge: ActivityChallenge?
    let likesCount: Int
    let commentsCount: Int
    let hasLiked: Bool
    let createdAt: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    static let mockData: [ActivityItem] = [
        ActivityItem(
            id: "1",
            type: "discovery",
            user: ActivityUser(id: "1", username: "adventurer123", avatarUrl: nil, level: 5),
            content: "Just found an amazing treasure hidden near the Golden Gate Bridge!",
            treasure: ActivityTreasure(
                id: "t1",
                title: "Bridge Mystery",
                description: "A challenging puzzle awaits at this iconic location",
                difficulty: "Hard",
                points: 150
            ),
            challenge: nil,
            likesCount: 24,
            commentsCount: 8,
            hasLiked: false,
            createdAt: Date().addingTimeInterval(-3600)
        )
    ]
}

struct ActivityUser: Codable {
    let id: String
    let username: String
    let avatarUrl: String?
    let level: Int
}

struct ActivityTreasure: Codable {
    let id: String
    let title: String
    let description: String
    let difficulty: String
    let points: Int
}

struct ActivityChallenge: Codable {
    let id: String
    let name: String
    let difficulty: String
    let rewardPoints: Int
}

struct ActivityComment: Identifiable {
    let id: String
    let user: ActivityUser
    let content: String
    let createdAt: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    static let mockData: [ActivityComment] = [
        ActivityComment(
            id: "1",
            user: ActivityUser(id: "2", username: "explorer99", avatarUrl: nil, level: 3),
            content: "Wow, that's amazing! How long did it take you to solve it?",
            createdAt: Date().addingTimeInterval(-1800)
        )
    ]
}