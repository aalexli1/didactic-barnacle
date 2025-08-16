import Foundation
import Contacts

struct Friend: Identifiable, Codable {
    let id: String
    let username: String
    let avatarUrl: String?
    let level: Int
    let totalPoints: Int
    let isOnline: Bool
}

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let fromUsername: String
    let toUserId: String
    let createdAt: Date
}

struct SuggestedFriend: Identifiable {
    let id: String
    let username: String
    let mutualFriends: Int
}

class FriendsService: ObservableObject {
    static let shared = FriendsService()
    
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var suggestedFriends: [SuggestedFriend] = []
    @Published var blockedUsers: [String] = []
    
    private let apiClient = APIClient.shared
    private let authService = AuthenticationService.shared
    
    private init() {
        loadFriends()
        loadFriendRequests()
    }
    
    func loadFriends() {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                friends = try await apiClient.getFriends(token: token.accessToken)
            } catch {
                print("Error loading friends: \(error)")
            }
        }
    }
    
    func loadFriendRequests() {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                friendRequests = try await apiClient.getFriendRequests(token: token.accessToken)
            } catch {
                print("Error loading friend requests: \(error)")
            }
        }
    }
    
    func sendFriendRequest(to userId: String) {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                try await apiClient.sendFriendRequest(token: token.accessToken, toUserId: userId)
                NotificationCenter.default.post(name: .friendRequestSent, object: nil)
            } catch {
                print("Error sending friend request: \(error)")
            }
        }
    }
    
    func sendFriendRequestByUsername(_ username: String) async throws {
        guard let token = authService.authToken else {
            throw AuthError.tokenExpired
        }
        
        try await apiClient.sendFriendRequestByUsername(token: token.accessToken, username: username)
        NotificationCenter.default.post(name: .friendRequestSent, object: nil)
    }
    
    func acceptFriendRequest(_ request: FriendRequest) {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                try await apiClient.acceptFriendRequest(token: token.accessToken, requestId: request.id)
                await MainActor.run {
                    friendRequests.removeAll { $0.id == request.id }
                }
                loadFriends()
                NotificationCenter.default.post(name: .friendRequestAccepted, object: nil)
            } catch {
                print("Error accepting friend request: \(error)")
            }
        }
    }
    
    func declineFriendRequest(_ request: FriendRequest) {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                try await apiClient.declineFriendRequest(token: token.accessToken, requestId: request.id)
                await MainActor.run {
                    friendRequests.removeAll { $0.id == request.id }
                }
            } catch {
                print("Error declining friend request: \(error)")
            }
        }
    }
    
    func removeFriend(_ friendId: String) {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                try await apiClient.removeFriend(token: token.accessToken, friendId: friendId)
                await MainActor.run {
                    friends.removeAll { $0.id == friendId }
                }
            } catch {
                print("Error removing friend: \(error)")
            }
        }
    }
    
    func blockUser(_ userId: String) {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                try await apiClient.blockUser(token: token.accessToken, userId: userId)
                await MainActor.run {
                    blockedUsers.append(userId)
                    friends.removeAll { $0.id == userId }
                    friendRequests.removeAll { $0.fromUserId == userId }
                }
            } catch {
                print("Error blocking user: \(error)")
            }
        }
    }
    
    func unblockUser(_ userId: String) {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                try await apiClient.unblockUser(token: token.accessToken, userId: userId)
                await MainActor.run {
                    blockedUsers.removeAll { $0 == userId }
                }
            } catch {
                print("Error unblocking user: \(error)")
            }
        }
    }
    
    func importContacts() {
        let store = CNContactStore()
        
        Task {
            do {
                let granted = try await store.requestAccess(for: .contacts)
                if granted {
                    let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]
                    let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
                    
                    var emails: [String] = []
                    try store.enumerateContacts(with: request) { contact, _ in
                        for email in contact.emailAddresses {
                            emails.append(email.value as String)
                        }
                    }
                    
                    if !emails.isEmpty {
                        guard let token = authService.authToken else { return }
                        suggestedFriends = try await apiClient.findFriendsByEmails(
                            token: token.accessToken,
                            emails: emails
                        )
                    }
                }
            } catch {
                print("Error importing contacts: \(error)")
            }
        }
    }
    
    func loadSuggestedFriends() {
        Task {
            guard let token = authService.authToken else { return }
            
            do {
                suggestedFriends = try await apiClient.getSuggestedFriends(token: token.accessToken)
            } catch {
                print("Error loading suggested friends: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let friendRequestSent = Notification.Name("friendRequestSent")
    static let friendRequestAccepted = Notification.Name("friendRequestAccepted")
}

extension APIClient {
    func getFriends(token: String) async throws -> [Friend] {
        let url = URL(string: "\(baseURL)/friends")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([Friend].self, from: data)
    }
    
    func getFriendRequests(token: String) async throws -> [FriendRequest] {
        let url = URL(string: "\(baseURL)/friends/requests")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([FriendRequest].self, from: data)
    }
    
    func sendFriendRequest(token: String, toUserId: String) async throws {
        let url = URL(string: "\(baseURL)/friends/request")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["toUserId": toUserId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await session.data(for: request)
    }
    
    func sendFriendRequestByUsername(token: String, username: String) async throws {
        let url = URL(string: "\(baseURL)/friends/request/username")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await session.data(for: request)
    }
    
    func acceptFriendRequest(token: String, requestId: String) async throws {
        let url = URL(string: "\(baseURL)/friends/request/\(requestId)/accept")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, _) = try await session.data(for: request)
    }
    
    func declineFriendRequest(token: String, requestId: String) async throws {
        let url = URL(string: "\(baseURL)/friends/request/\(requestId)/decline")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, _) = try await session.data(for: request)
    }
    
    func removeFriend(token: String, friendId: String) async throws {
        let url = URL(string: "\(baseURL)/friends/\(friendId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, _) = try await session.data(for: request)
    }
    
    func blockUser(token: String, userId: String) async throws {
        let url = URL(string: "\(baseURL)/users/block")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await session.data(for: request)
    }
    
    func unblockUser(token: String, userId: String) async throws {
        let url = URL(string: "\(baseURL)/users/unblock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await session.data(for: request)
    }
    
    func findFriendsByEmails(token: String, emails: [String]) async throws -> [SuggestedFriend] {
        let url = URL(string: "\(baseURL)/friends/find-by-emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["emails": emails]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([SuggestedFriend].self, from: data)
    }
    
    func getSuggestedFriends(token: String) async throws -> [SuggestedFriend] {
        let url = URL(string: "\(baseURL)/friends/suggested")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([SuggestedFriend].self, from: data)
    }
}