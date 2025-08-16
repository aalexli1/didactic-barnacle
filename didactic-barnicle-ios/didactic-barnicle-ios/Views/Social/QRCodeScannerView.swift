import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @StateObject private var viewModel = QRCodeScannerViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingQRCode = false
    @State private var showingScanner = false
    @State private var scanResult: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Friends")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingQRCode = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Show My QR Code")
                                    .fontWeight(.semibold)
                                Text("Let others scan to add you")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Scan QR Code")
                                    .fontWeight(.semibold)
                                Text("Scan a friend's code to connect")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingQRCode) {
                MyQRCodeView()
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerView(completion: { result in
                    scanResult = result
                    showingScanner = false
                    viewModel.processScanResult(result)
                })
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct MyQRCodeView: View {
    @StateObject private var viewModel = MyQRCodeViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let qrCodeImage = viewModel.qrCodeImage {
                    VStack(spacing: 16) {
                        Text("My Friend Code")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Image(uiImage: qrCodeImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        
                        Text("Let others scan this code to add you as a friend")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        ShareLink(item: qrCodeImage, preview: SharePreview("My Friend QR Code", image: qrCodeImage)) {
                            Label("Share QR Code", systemImage: "square.and.arrow.up")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    Text("Failed to generate QR code")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                viewModel.generateQRCode()
            }
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    let completion: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.completion = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var completion: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
        dismiss(animated: true)
    }
    
    func found(code: String) {
        completion?(code)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

class QRCodeScannerViewModel: ObservableObject {
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let friendsService = FriendsService.shared
    
    func processScanResult(_ result: String) {
        Task {
            do {
                guard let data = result.data(using: .utf8),
                      let friendData = try? JSONDecoder().decode(FriendQRData.self, from: data) else {
                    await showError("Invalid QR Code", message: "This QR code is not valid for adding friends.")
                    return
                }
                
                if friendData.type != "friend_request" {
                    await showError("Invalid QR Code", message: "This QR code is not for adding friends.")
                    return
                }
                
                try await sendFriendRequest(to: friendData.userId)
                await showSuccess("Friend Request Sent", message: "Your friend request has been sent successfully!")
                
            } catch {
                await showError("Failed to Send Request", message: error.localizedDescription)
            }
        }
    }
    
    private func sendFriendRequest(to userId: String) async throws {
        guard let token = AuthenticationService.shared.authToken else {
            throw AuthError.tokenExpired
        }
        
        let url = URL(string: "\(APIClient.shared.baseURL)/friends/scan")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["qrData": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
    }
    
    @MainActor
    private func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    @MainActor
    private func showSuccess(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

class MyQRCodeViewModel: ObservableObject {
    @Published var qrCodeImage: UIImage?
    @Published var isLoading = false
    
    func generateQRCode() {
        isLoading = true
        
        Task {
            do {
                guard let token = AuthenticationService.shared.authToken else {
                    throw AuthError.tokenExpired
                }
                
                let url = URL(string: "\(APIClient.shared.baseURL)/friends/qrcode")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(QRCodeResponse.self, from: data)
                
                if let qrCodeData = Data(base64Encoded: response.qrCode.replacingOccurrences(of: "data:image/png;base64,", with: "")),
                   let image = UIImage(data: qrCodeData) {
                    await MainActor.run {
                        self.qrCodeImage = image
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct FriendQRData: Codable {
    let type: String
    let userId: String
    let username: String
    let timestamp: Int64
    
    enum CodingKeys: String, CodingKey {
        case type
        case userId = "user_id"
        case username
        case timestamp
    }
}

struct QRCodeResponse: Codable {
    let qrCode: String
    let data: FriendQRData
}

enum APIError: Error {
    case invalidResponse
    case decodingError
}