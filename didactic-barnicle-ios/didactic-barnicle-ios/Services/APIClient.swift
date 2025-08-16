import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidCredentials
    case emailAlreadyExists
    case usernameAlreadyExists
    case networkError
    case serverError(Int)
    case decodingError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidCredentials:
            return "Invalid credentials"
        case .emailAlreadyExists:
            return "Email already exists"
        case .usernameAlreadyExists:
            return "Username already exists"
        case .networkError:
            return "Network error"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .unknown(let message):
            return message
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    // For local development testing
    private let baseURL = "http://localhost:3000/api"
    // Production URL: "https://api.artreasurehunt.com/v1"
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    func signUp(request: SignUpRequest) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/signup")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        case 400:
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                if error.code == "EMAIL_EXISTS" {
                    throw APIError.emailAlreadyExists
                } else if error.code == "USERNAME_EXISTS" {
                    throw APIError.usernameAlreadyExists
                }
            }
            throw APIError.invalidCredentials
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func signIn(request: SignInRequest) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/signin")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func signInWithApple(identityToken: Data, authorizationCode: Data) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/apple")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "identityToken": identityToken.base64EncodedString(),
            "authorizationCode": authorizationCode.base64EncodedString()
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func refreshToken(refreshToken: String) async throws -> AuthToken {
        let url = URL(string: "\(baseURL)/auth/refresh")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(AuthToken.self, from: data)
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func resetPassword(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/reset-password")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func getUserProfile(token: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me")!
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(User.self, from: data)
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func updateProfile(token: String, username: String? = nil, avatarUrl: String? = nil) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [:]
        if let username = username {
            body["username"] = username
        }
        if let avatarUrl = avatarUrl {
            body["avatarUrl"] = avatarUrl
        }
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(User.self, from: data)
        case 400:
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                if error.code == "USERNAME_EXISTS" {
                    throw APIError.usernameAlreadyExists
                }
            }
            throw APIError.invalidResponse
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func updatePrivacySettings(token: String, settings: PrivacySettings) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me/privacy")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(settings)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(User.self, from: data)
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

struct ErrorResponse: Codable {
    let code: String
    let message: String
}