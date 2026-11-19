import Foundation

@MainActor
final class AgentStream: ObservableObject {
    @Published private(set) var lastEvent = "Chưa kết nối"
    @Published private(set) var isConnected = false
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = Data()
    private let pc: PairedPC

    init(pc: PairedPC) { self.pc = pc }

    func start() {
        guard let host = pc.hosts.first,
              let url = URL(string: "https://\(host):\(pc.port)/api/stream") else { return }
        let delegate = StreamTrustDelegate(fingerprint: pc.fingerprint)
        let config = URLSessionConfiguration.ephemeral
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: .main)
        var request = URLRequest(url: url)
        request.setValue("Bearer \(pc.token)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        task = session?.dataTask(with: request)
        task?.resume()
    }

    func stop() {
        task?.cancel()
        session?.invalidateAndCancel()
        task = nil
        session = nil
        isConnected = false
    }
}

private final class StreamTrustDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    let fingerprint: String
    init(fingerprint: String) { self.fingerprint = fingerprint }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust,
              let cert = SecTrustGetCertificateAtIndex(trust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil); return
        }
        let hash = SHA256.hash(data: SecCertificateCopyData(cert) as Data).map { String(format: "%02x", $0) }.joined()
        completionHandler(hash == fingerprint ? .useCredential : .cancelAuthenticationChallenge,
                          hash == fingerprint ? URLCredential(trust: trust) : nil)
    }
}
