import SwiftUI

struct FriendsListView: View {
    @StateObject private var friendsService = FriendsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingAddFriend = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Friends", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                    Text("Find Friends").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedTab {
                case 0:
                    friendsList
                case 1:
                    friendRequests
                case 2:
                    findFriends
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Friends")
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                },
                trailing: Button(action: {
                    showingAddFriend = true
                }) {
                    Image(systemName: "person.badge.plus")
                }
            )
            .searchable(text: $searchText, prompt: "Search friends")
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
        }
    }
    
    private var friendsList: some View {
        ScrollView {
            if friendsService.friends.isEmpty {
                emptyFriendsState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredFriends) { friend in
                        FriendRow(friend: friend)
                    }
                }
                .padding()
            }
        }
    }
    
    private var friendRequests: some View {
        ScrollView {
            if friendsService.friendRequests.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Friend Requests")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(friendsService.friendRequests) { request in
                        FriendRequestRow(request: request)
                    }
                }
                .padding()
            }
        }
    }
    
    private var findFriends: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button(action: {
                    friendsService.importContacts()
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Import from Contacts")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Friends")
                        .font(.headline)
                    
                    if friendsService.suggestedFriends.isEmpty {
                        Text("No suggestions available")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        ForEach(friendsService.suggestedFriends) { suggestion in
                            SuggestedFriendRow(friend: suggestion)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyFriendsState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add friends to compete and share treasures!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Find Friends") {
                selectedTab = 2
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.top, 100)
    }
    
    private var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friendsService.friends
        } else {
            return friendsService.friends.filter {
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct FriendRow: View {
    let friend: Friend
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: friend.avatarUrl ?? "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(friend.username)
                    .font(.headline)
                
                HStack {
                    Text("Level \(friend.level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(friend.totalPoints) points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: {}) {
                    Label("View Profile", systemImage: "person.fill")
                }
                
                Button(action: {}) {
                    Label("Send Message", systemImage: "message.fill")
                }
                
                Button(action: {}, role: .destructive) {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    @StateObject private var friendsService = FriendsService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(request.fromUsername)
                    .font(.headline)
                
                Text("Wants to be your friend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    friendsService.acceptFriendRequest(request)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    friendsService.declineFriendRequest(request)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct SuggestedFriendRow: View {
    let friend: SuggestedFriend
    @StateObject private var friendsService = FriendsService.shared
    @State private var requestSent = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(friend.username)
                    .font(.headline)
                
                Text(friend.mutualFriends > 0 ? "\(friend.mutualFriends) mutual friends" : "New treasure hunter")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                friendsService.sendFriendRequest(to: friend.id)
                requestSent = true
            }) {
                if requestSent {
                    Image(systemName: "checkmark")
                        .foregroundColor(.gray)
                } else {
                    Text("Add")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            .disabled(requestSent)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @StateObject private var friendsService = FriendsService.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Friend by Username")
                    .font(.headline)
                    .padding(.top, 40)
                
                TextField("Enter username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)
                
                Button(action: sendFriendRequest) {
                    Text("Send Friend Request")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(username.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(username.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Friend request sent!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func sendFriendRequest() {
        Task {
            do {
                try await friendsService.sendFriendRequestByUsername(username)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}