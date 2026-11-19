import Foundation
import CryptoKit

final class AgentClient: NSObject, URLSessionDelegate {
    private(set) var pc: PairedPC
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 35
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    init(pc: PairedPC) { self.pc = pc }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil); return
        }
        let certData = SecCertificateCopyData(certificate) as Data
        let digest = SHA256.hash(data: certData).map { String(format: "%02x", $0) }.joined()
        guard digest.caseInsensitiveCompare(pc.fingerprint) == .orderedSame else {
            completionHandler(.cancelAuthenticationChallenge, nil); return
        }
        // Trust only this exact certificate; never disable TLS validation globally.
        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    func request<T: Decodable>(_ path: String, method: String = "GET",
                               body: Data? = nil, as type: T.Type = T.self) async throws -> T {
        guard let host = pc.hosts.first,
              let url = URL(string: "https://\(host):\(pc.port)\(path)") else {
            throw PhoneBoxError.notPaired
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(pc.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("PhoneBox-X-iOS/0.1", forHTTPHeaderField: "X-PhoneBox-App")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PhoneBoxError.badResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func rawRequest(_ path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let host = pc.hosts.first,
              let url = URL(string: "https://\(host):\(pc.port)\(path)") else {
            throw PhoneBoxError.notPaired
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(pc.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PhoneBoxError.badResponse
        }
        return data
    }

    func close() { session.invalidateAndCancel() }
}
