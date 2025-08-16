import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingEditProfile = false
    @State private var showingPrivacySettings = false
    @State private var showingFriends = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsSection
                    menuSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Edit") {
                showingEditProfile = true
            })
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showingFriends) {
                FriendsListView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: authService.currentUser?.avatarUrl ?? "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(authService.currentUser?.username ?? "Unknown User")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(authService.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let user = authService.currentUser {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(user.isEmailVerified ? .green : .gray)
                    Text(user.isEmailVerified ? "Verified" : "Not Verified")
                        .font(.caption)
                        .foregroundColor(user.isEmailVerified ? .green : .gray)
                }
            }
        }
        .padding(.vertical)
    }
    
    private var statsSection: some View {
        HStack(spacing: 30) {
            VStack {
                Text("\(UserService.shared.totalPoints)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("Level \(UserService.shared.level)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Current Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(UserService.shared.currentUser?.treasuresCollected ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Treasures")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var menuSection: some View {
        VStack(spacing: 0) {
            MenuRow(
                icon: "person.2.fill",
                title: "Friends",
                action: { showingFriends = true }
            )
            
            MenuRow(
                icon: "trophy.fill",
                title: "Achievements",
                destination: AchievementsView()
            )
            
            MenuRow(
                icon: "lock.fill",
                title: "Privacy Settings",
                action: { showingPrivacySettings = true }
            )
            
            MenuRow(
                icon: "faceid",
                title: "Biometric Authentication",
                destination: BiometricSettingsView()
            )
            
            MenuRow(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                destination: HelpSupportView()
            )
            
            MenuRow(
                icon: "arrow.right.square.fill",
                title: "Sign Out",
                action: { showingSignOutAlert = true },
                isDestructive: true
            )
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MenuRow<Destination: View>: View {
    let icon: String
    let title: String
    var destination: Destination? = nil
    var action: (() -> Void)? = nil
    var isDestructive: Bool = false
    
    init(icon: String, title: String, destination: Destination, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.destination = destination
        self.isDestructive = isDestructive
    }
    
    init(icon: String, title: String, action: @escaping () -> Void, isDestructive: Bool = false) where Destination == EmptyView {
        self.icon = icon
        self.title = title
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    rowContent
                }
            } else if let action = action {
                Button(action: action) {
                    rowContent
                }
            }
        }
    }
    
    private var rowContent: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .blue)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(isDestructive ? .red : .primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
    }
}