import SwiftUI
import AVFoundation

struct PairingIntroView: View {
    @EnvironmentObject private var store: AppStore
    @State private var manualQR = ""
    @State private var scan = false

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 64, weight: .light)).foregroundStyle(.cyan)
            Text("Kết nối với PC").font(.title2.bold())
            Text("Mở PhoneBox Agent trên máy tính, bật LAN access và tạo mã QR ghép đôi.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button { scan = true } label: {
                Label("Quét mã QR", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity).padding()
            }.buttonStyle(.borderedProminent)
            Text("Hoặc dán link ghép đôi").font(.caption).foregroundStyle(.secondary)
            TextField("https://ersinkoc.github.io/phonebox/pair/#...", text: $manualQR, axis: .vertical)
                .textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
            Button("Ghép đôi") {
                Task { await store.pair(qr: manualQR) }
            }.disabled(manualQR.isEmpty)
            Spacer()
            Text("iPhone và PC cần chung Wi-Fi hoặc cùng mạng Tailscale.")
                .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding()
        .sheet(isPresented: $scan) {
            QRScanner { value in
                scan = false
                Task { await store.pair(qr: value) }
            }
            .ignoresSafeArea()
        }
    }
}

struct QRScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.onCode = onCode
        return controller
    }
    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}
}

final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let session = AVCaptureSession()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        session.startRunning()
    }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = code.stringValue else { return }
        session.stopRunning()
        onCode?(value)
    }
}
