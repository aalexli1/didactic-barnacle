import SwiftUI

struct ProfileView: View {
    @State private var userProfile = UserProfile(
        id: UUID().uuidString,
        username: "TreasureHunter",
        email: "hunter@example.com",
        totalTreasuresFound: 12,
        totalPoints: 1200,
        level: 5,
        joinedDate: Date()
    )
    @State private var showingSettings = false
    @State private var showingAchievements = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeaderView(profile: userProfile)
                    
                    StatsView(profile: userProfile)
                    
                    VStack(spacing: 12) {
                        NavigationLink(destination: AchievementsView()) {
                            ProfileMenuRow(
                                icon: "trophy.fill",
                                title: "Achievements",
                                color: .yellow
                            )
                        }
                        
                        NavigationLink(destination: LeaderboardView()) {
                            ProfileMenuRow(
                                icon: "chart.bar.fill",
                                title: "Leaderboard",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: HistoryView()) {
                            ProfileMenuRow(
                                icon: "clock.arrow.circlepath",
                                title: "Hunt History",
                                color: .green
                            )
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            ProfileMenuRow(
                                icon: "gearshape.fill",
                                title: "Settings",
                                color: .gray
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(profile: $userProfile)
            }
        }
    }
}

struct ProfileHeaderView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text(profile.username)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Level \(profile.level)")
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
        }
        .padding()
    }
}

struct StatsView: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 30) {
            StatItem(
                value: "\(profile.totalTreasuresFound)",
                label: "Treasures",
                icon: "star.fill",
                color: .yellow
            )
            
            StatItem(
                value: "\(profile.totalPoints)",
                label: "Points",
                icon: "bitcoinsign.circle.fill",
                color: .orange
            )
            
            StatItem(
                value: "\(profile.level)",
                label: "Level",
                icon: "arrow.up.circle.fill",
                color: .green
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct EditProfileView: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var username: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profile.username = username
                        profile.email = email
                        dismiss()
                    }
                }
            }
            .onAppear {
                username = profile.username
                email = profile.email
            }
        }
    }
}

struct AchievementsView: View {
    var body: some View {
        List {
            AchievementRow(
                title: "First Treasure",
                description: "Find your first treasure",
                isUnlocked: true,
                icon: "star.fill"
            )
            AchievementRow(
                title: "Treasure Hunter",
                description: "Find 10 treasures",
                isUnlocked: true,
                icon: "star.circle.fill"
            )
            AchievementRow(
                title: "Master Explorer",
                description: "Find 50 treasures",
                isUnlocked: false,
                icon: "crown.fill"
            )
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isUnlocked ? .yellow : .gray)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LeaderboardView: View {
    var body: some View {
        List {
            ForEach(0..<10) { index in
                HStack {
                    Text("\(index + 1)")
                        .fontWeight(.bold)
                        .frame(width: 30)
                    
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("Player \(index + 1)")
                    
                    Spacer()
                    
                    Text("\(1000 - index * 50) pts")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryView: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Golden Star Treasure")
                        .fontWeight(.semibold)
                    Text("Found \(index + 1) days ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Hunt History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                Toggle("Sound Effects", isOn: $soundEnabled)
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
            }
            
            Section("Privacy") {
                NavigationLink(destination: Text("Privacy Policy")) {
                    Text("Privacy Policy")
                }
                NavigationLink(destination: Text("Terms of Service")) {
                    Text("Terms of Service")
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}