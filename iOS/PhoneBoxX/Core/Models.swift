import Foundation

struct PairingPayload: Decodable {
    let pc: String
    let fingerprint: String
    let port: Int
    let hosts: [String]
    let code: String

    static func parse(qr: String) throws -> PairingPayload {
        guard let url = URL(string: qr),
              let fragment = url.fragment, !fragment.isEmpty else {
            throw PhoneBoxError.invalidPairingQR
        }
        let parts = URLComponents(string: "https://placeholder.invalid/#" + fragment)
        let values = Dictionary((parts?.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        }, uniquingKeysWith: { _, latest in latest })

        guard values["v"] == "1",
              let pc = values["pc"], !pc.isEmpty,
              let fp = values["fp"], fp.count == 64,
              let portString = values["port"], let port = Int(portString),
              (1024...65535).contains(port),
              let hostsRaw = values["h"],
              let code = values["c"], !code.isEmpty else {
            throw PhoneBoxError.invalidPairingQR
        }
        let hosts = hostsRaw.split(separator: ",").compactMap {
            String($0).removingPercentEncoding ?? String($0)
        }
        guard !hosts.isEmpty else { throw PhoneBoxError.invalidPairingQR }
        return PairingPayload(pc: pc, fingerprint: fp.lowercased(), port: port, hosts: hosts, code: code)
    }
}

struct PairedPC: Codable, Identifiable, Equatable {
    var id: String { fingerprint }
    let name: String
    let hosts: [String]
    let port: Int
    let token: String
    let fingerprint: String
    var baseURL: URL? {
        hosts.first.flatMap { URL(string: "https://\($0):\(port)") }
    }
}

struct AgentSnapshot: Decodable {
    var cpu: Double?
    var memory: Double?
    var gpu: Double?
    var hostname: String?
    var os: String?
    var uptime: String?
    var raw: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case cpu, memory, gpu, hostname, os, uptime
    }
}

enum JSONValue: Decodable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
        else if let v = try? c.decode([JSONValue].self) { self = .array(v) }
        else { self = .null }
    }
}

enum PhoneBoxError: LocalizedError {
    case invalidPairingQR, certificateMismatch, pairingRejected, notPaired, badResponse
    var errorDescription: String? {
        switch self {
        case .invalidPairingQR: "QR code không đúng định dạng PhoneBox."
        case .certificateMismatch: "Chứng chỉ PC không khớp fingerprint trong QR. Đã hủy ghép đôi."
        case .pairingRejected: "PC từ chối mã ghép đôi hoặc mã đã hết hạn."
        case .notPaired: "Chưa ghép đôi với PC."
        case .badResponse: "PC trả về dữ liệu không hợp lệ."
        }
    }
}
