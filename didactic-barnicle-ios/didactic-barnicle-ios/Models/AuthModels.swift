import Foundation

struct AuthCredentials {
    let email: String
    let password: String
}

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let username: String
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let user: AuthUser
    let token: AuthToken
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let username: String
    let avatarUrl: String?
    let isEmailVerified: Bool
    let createdAt: Date
    let privacySettings: PrivacySettings?
}

struct PrivacySettings: Codable {
    var profileVisibility: ProfileVisibility = .public
    var showLocation: Bool = false
    var allowFriendRequests: Bool = true
    var treasureVisibility: TreasureVisibility = .friends
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
}

enum TreasureVisibility: String, Codable, CaseIterable {
    case everyone = "everyone"
    case friends = "friends"
    case onlyMe = "only_me"
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case usernameAlreadyExists
    case weakPassword
    case networkError
    case tokenExpired
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .usernameAlreadyExists:
            return "This username is already taken"
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers"
        case .networkError:
            return "Network connection error. Please try again"
        case .tokenExpired:
            return "Your session has expired. Please sign in again"
        case .unknown(let message):
            return message
        }
    }
}