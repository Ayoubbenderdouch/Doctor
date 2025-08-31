
import SwiftUI
import AVFoundation
import Vision

struct QRScanView: View {
    @StateObject private var viewModel = QRScanViewModel()
    @State private var showingResult = false
    @State private var resultMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isAuthorized {
                    CameraView(viewModel: viewModel)
                        .ignoresSafeArea()

                    VStack {
                        Spacer()

                        // Scanning frame
                        Image(systemName: "viewfinder")
                            .font(.system(size: 250))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        // Instructions
                        VStack(spacing: 20) {
                            Text("Placez le QR code dans le cadre")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(25)

                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                        .padding(.bottom, 50)
                    }
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Accès à la caméra requis")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Veuillez autoriser l'accès à la caméra pour scanner les codes QR")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button(action: openSettings) {
                            Text("Ouvrir les paramètres")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.appPrimary)
                                .cornerRadius(25)
                        }
                    }
                }
            }
            .navigationTitle("Scanner QR")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.checkAuthorization()
            }
            .onChange(of: viewModel.scannedCode) { code in
                if let code = code {
                    handleScannedCode(code)
                }
            }
            .alert("Résultat", isPresented: $showingResult) {
                Button("OK") {
                    viewModel.resumeScanning()
                }
            } message: {
                Text(resultMessage)
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.resumeScanning()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        Task {
            viewModel.isProcessing = true

            do {
                let success = try await APIService.shared.scanQRCode(code)
                if success {
                    resultMessage = "Check-in réussi! ✅\nVous pouvez vous présenter à la réception."
                } else {
                    resultMessage = "Code QR invalide ou expiré"
                }
            } catch {
                resultMessage = "Erreur lors de la vérification: \(error.localizedDescription)"
            }

            viewModel.isProcessing = false
            showingResult = true
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let viewModel: QRScanViewModel

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.viewModel = viewModel
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var viewModel: QRScanViewModel?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              let captureSession = captureSession else { return }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill

        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession?.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            viewModel?.scannedCode = stringValue
        }
    }
}

class QRScanViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var scannedCode: String?
    @Published var isProcessing = false
    @Published var errorMessage = ""
    @Published var showError = false

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                }
            }
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    func resumeScanning() {
        scannedCode = nil
        isProcessing = false
    }
}
