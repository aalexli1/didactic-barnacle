import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var profileVisibility: ProfileVisibility = .public
    @State private var treasureVisibility: TreasureVisibility = .friends
    @State private var showLocation = false
    @State private var allowFriendRequests = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasChanges = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Visibility")) {
                    Picker("Who can see your profile", selection: $profileVisibility) {
                        ForEach(ProfileVisibility.allCases, id: \.self) { visibility in
                            Text(visibilityLabel(visibility)).tag(visibility)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: profileVisibility) { _ in hasChanges = true }
                    
                    Text(visibilityDescription(profileVisibility))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Treasure Settings")) {
                    Picker("Treasure visibility", selection: $treasureVisibility) {
                        ForEach(TreasureVisibility.allCases, id: \.self) { visibility in
                            Text(treasureVisibilityLabel(visibility)).tag(visibility)
                        }
                    }
                    .onChange(of: treasureVisibility) { _ in hasChanges = true }
                    
                    Toggle("Show my location on map", isOn: $showLocation)
                        .onChange(of: showLocation) { _ in hasChanges = true }
                    
                    Text("When enabled, friends can see your approximate location on the treasure map")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Social Settings")) {
                    Toggle("Allow friend requests", isOn: $allowFriendRequests)
                        .onChange(of: allowFriendRequests) { _ in hasChanges = true }
                    
                    if !allowFriendRequests {
                        Text("You won't receive new friend requests. Existing friends remain connected.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Data & Privacy")) {
                    NavigationLink(destination: BlockedUsersView()) {
                        HStack {
                            Text("Blocked Users")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: DataExportView()) {
                        HStack {
                            Text("Export My Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Delete Account") {
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                }
                .disabled(!hasChanges || authService.isLoading)
            )
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let settings = authService.currentUser?.privacySettings {
            profileVisibility = settings.profileVisibility
            treasureVisibility = settings.treasureVisibility
            showLocation = settings.showLocation
            allowFriendRequests = settings.allowFriendRequests
        }
    }
    
    private func saveSettings() {
        let settings = PrivacySettings(
            profileVisibility: profileVisibility,
            showLocation: showLocation,
            allowFriendRequests: allowFriendRequests,
            treasureVisibility: treasureVisibility
        )
        
        Task {
            do {
                try await authService.updatePrivacySettings(settings)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func visibilityLabel(_ visibility: ProfileVisibility) -> String {
        switch visibility {
        case .public:
            return "Public"
        case .friends:
            return "Friends"
        case .private:
            return "Private"
        }
    }
    
    private func visibilityDescription(_ visibility: ProfileVisibility) -> String {
        switch visibility {
        case .public:
            return "Anyone can view your profile and stats"
        case .friends:
            return "Only friends can view your profile"
        case .private:
            return "Your profile is hidden from everyone"
        }
    }
    
    private func treasureVisibilityLabel(_ visibility: TreasureVisibility) -> String {
        switch visibility {
        case .everyone:
            return "Everyone"
        case .friends:
            return "Friends Only"
        case .onlyMe:
            return "Only Me"
        }
    }
}

struct BlockedUsersView: View {
    var body: some View {
        Text("Blocked Users")
            .navigationTitle("Blocked Users")
    }
}

struct DataExportView: View {
    var body: some View {
        Text("Export Data")
            .navigationTitle("Export My Data")
    }
}