import Foundation
import CryptoKit

struct PairClaim: Encodable { let code: String }
struct PairClaimReply: Decodable {
    let token: String
    let pc: String?
    let fingerprint: String?
    let hosts: [String]?
    let port: Int?
}

enum PairingManager {
    static func claim(_ payload: PairingPayload) async throws -> PairedPC {
        var lastError: Error = PhoneBoxError.pairingRejected
        for host in payload.hosts {
            guard let url = URL(string: "https://\(host):\(payload.port)/api/pair/claim") else { continue }
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 10
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(PairClaim(code: payload.code))
                let delegate = PairingTrustDelegate(fingerprint: payload.fingerprint)
                let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
                defer { session.invalidateAndCancel() }
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw PhoneBoxError.pairingRejected
                }
                let reply = try JSONDecoder().decode(PairClaimReply.self, from: data)
                return PairedPC(name: reply.pc ?? payload.pc,
                                hosts: reply.hosts ?? payload.hosts,
                                port: reply.port ?? payload.port,
                                token: reply.token,
                                fingerprint: reply.fingerprint ?? payload.fingerprint)
            } catch { lastError = error }
        }
        throw lastError
    }
}

private final class PairingTrustDelegate: NSObject, URLSessionDelegate {
    let fingerprint: String
    init(fingerprint: String) { self.fingerprint = fingerprint.lowercased() }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil); return
        }
        let data = SecCertificateCopyData(certificate) as Data
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == fingerprint else {
            completionHandler(.cancelAuthenticationChallenge, nil); return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
