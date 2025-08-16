import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var selectedAvatar: String = "person.circle.fill"
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    
    let avatarOptions = [
        "person.circle.fill",
        "face.smiling.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "bolt.circle.fill",
        "flame.circle.fill",
        "leaf.circle.fill",
        "pawprint.circle.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    VStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: selectedAvatar)
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                        }
                        
                        Button("Choose Photo") {
                            showingImagePicker = true
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(avatarOptions, id: \.self) { avatar in
                                Button(action: {
                                    selectedAvatar = avatar
                                    selectedImage = nil
                                }) {
                                    Image(systemName: avatar)
                                        .font(.system(size: 40))
                                        .foregroundColor(selectedAvatar == avatar && selectedImage == nil ? .blue : .gray)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section(header: Text("Username")) {
                    TextField("Enter username", text: $username)
                        .autocapitalization(.none)
                    
                    Text("Your username must be unique and can contain letters, numbers, and underscores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Account Info")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authService.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Member Since")
                        Spacer()
                        Text(formatDate(authService.currentUser?.createdAt))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .disabled(authService.isLoading)
            )
            .onAppear {
                username = authService.currentUser?.username ?? ""
                if let avatarUrl = authService.currentUser?.avatarUrl {
                    selectedAvatar = avatarUrl
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveProfile() {
        Task {
            do {
                var avatarUrl: String? = nil
                
                if selectedImage != nil {
                    avatarUrl = "custom_avatar"
                } else {
                    avatarUrl = selectedAvatar
                }
                
                try await authService.updateProfile(
                    username: username.isEmpty ? nil : username,
                    avatarUrl: avatarUrl
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.selectedImage = uiImage
                    }
                }
            }
        }
    }
}