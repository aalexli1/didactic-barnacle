import Foundation
import Combine
import LocalAuthentication

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: AuthToken?
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private let keychainService = KeychainService.shared
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    private let context = LAContext()
    
    private init() {
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        do {
            let token = try keychainService.loadToken()
            if !token.isExpired {
                authToken = token
                isAuthenticated = true
                loadUserProfile()
            } else {
                try refreshToken()
            }
        } catch {
            isAuthenticated = false
        }
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidCredentials
        }
        
        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = SignUpRequest(email: email, password: password, username: username)
        
        do {
            let response = try await apiClient.signUp(request: request)
            try keychainService.saveToken(response.token)
            
            authToken = response.token
            currentUser = response.user
            isAuthenticated = true
            
            UserDefaults.standard.set(response.user.id, forKey: "userId")
        } catch {
            throw mapError(error)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidCredentials
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = SignInRequest(email: email, password: password)
        
        do {
            let response = try await apiClient.signIn(request: request)
            try keychainService.saveToken(response.token)
            
            authToken = response.token
            currentUser = response.user
            isAuthenticated = true
            
            UserDefaults.standard.set(response.user.id, forKey: "userId")
        } catch {
            throw mapError(error)
        }
    }
    
    func signInWithApple(identityToken: Data, authorizationCode: Data) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await apiClient.signInWithApple(
                identityToken: identityToken,
                authorizationCode: authorizationCode
            )
            try keychainService.saveToken(response.token)
            
            authToken = response.token
            currentUser = response.user
            isAuthenticated = true
            
            UserDefaults.standard.set(response.user.id, forKey: "userId")
        } catch {
            throw mapError(error)
        }
    }
    
    func signInWithBiometrics() async throws {
        guard keychainService.isBiometricEnabled() else {
            throw AuthError.unknown("Biometric authentication not enabled")
        }
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.unknown(error?.localizedDescription ?? "Biometric authentication not available")
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to AR Treasure Hunt"
            )
            
            if success {
                let token = try keychainService.loadToken()
                if token.isExpired {
                    try await refreshToken()
                } else {
                    authToken = token
                    isAuthenticated = true
                    await loadUserProfile()
                }
            }
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func enableBiometricAuthentication() async throws {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.unknown(error?.localizedDescription ?? "Biometric authentication not available")
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Enable biometric authentication for quick sign in"
            )
            
            if success {
                keychainService.saveBiometricEnabled(true)
            }
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func disableBiometricAuthentication() {
        keychainService.saveBiometricEnabled(false)
    }
    
    func refreshToken() async throws {
        guard let token = authToken else {
            throw AuthError.tokenExpired
        }
        
        do {
            let newToken = try await apiClient.refreshToken(refreshToken: token.refreshToken)
            try keychainService.saveToken(newToken)
            authToken = newToken
        } catch {
            isAuthenticated = false
            throw AuthError.tokenExpired
        }
    }
    
    func resetPassword(email: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidCredentials
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiClient.resetPassword(email: email)
        } catch {
            throw mapError(error)
        }
    }
    
    func signOut() {
        do {
            try keychainService.deleteToken()
        } catch {
            print("Error deleting token: \(error)")
        }
        
        authToken = nil
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    func loadUserProfile() async {
        guard let token = authToken else { return }
        
        do {
            currentUser = try await apiClient.getUserProfile(token: token.accessToken)
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    func updateProfile(username: String? = nil, avatarUrl: String? = nil) async throws {
        guard let token = authToken else {
            throw AuthError.tokenExpired
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await apiClient.updateProfile(
                token: token.accessToken,
                username: username,
                avatarUrl: avatarUrl
            )
            currentUser = updatedUser
        } catch {
            throw mapError(error)
        }
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings) async throws {
        guard let token = authToken else {
            throw AuthError.tokenExpired
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await apiClient.updatePrivacySettings(
                token: token.accessToken,
                settings: settings
            )
            currentUser = updatedUser
        } catch {
            throw mapError(error)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
    
    private func mapError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidCredentials:
                return .invalidCredentials
            case .emailAlreadyExists:
                return .emailAlreadyExists
            case .usernameAlreadyExists:
                return .usernameAlreadyExists
            case .networkError:
                return .networkError
            default:
                return .unknown(apiError.localizedDescription)
            }
        }
        
        return .unknown(error.localizedDescription)
    }
}