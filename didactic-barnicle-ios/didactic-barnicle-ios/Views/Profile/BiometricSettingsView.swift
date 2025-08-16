import SwiftUI
import LocalAuthentication

struct BiometricSettingsView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var biometricEnabled = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var biometricType: LABiometryType = .none
    
    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield.fill"
        }
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: biometricIcon)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(biometricName)
                            .font(.headline)
                        Text("Use \(biometricName) to quickly sign in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $biometricEnabled)
                        .onChange(of: biometricEnabled) { newValue in
                            toggleBiometric(enabled: newValue)
                        }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("About \(biometricName)")) {
                Text("When enabled, you can use \(biometricName) to sign in without entering your password.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Text("Your biometric data is stored securely on your device and never leaves it.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            if biometricEnabled {
                Section(header: Text("Security")) {
                    Text("You'll still need to enter your password if:")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(biometricName) fails multiple times", systemImage: "xmark.circle.fill")
                        Label("You haven't used the app in 48 hours", systemImage: "clock.fill")
                        Label("Your device was restarted", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Biometric Authentication")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkBiometricAvailability()
            biometricEnabled = KeychainService.shared.isBiometricEnabled()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }
    
    private func toggleBiometric(enabled: Bool) {
        if enabled {
            Task {
                do {
                    try await authService.enableBiometricAuthentication()
                } catch {
                    biometricEnabled = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        } else {
            authService.disableBiometricAuthentication()
        }
    }
}