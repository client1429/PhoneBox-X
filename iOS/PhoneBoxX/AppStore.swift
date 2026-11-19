import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var pairedPC: PairedPC? = KeychainStore.load(PairedPC.self, service: "PhoneBoxX", account: "active-pc")
    @Published var snapshot: [String: JSONValue] = [:]
    @Published var isOnline = false
    @Published var errorMessage: String?
    @Published var showingPairing = false
    private var pollTask: Task<Void, Never>?

    func pair(qr: String) async {
        do {
            let payload = try PairingPayload.parse(qr: qr)
            let pc = try await PairingManager.claim(payload)
            try KeychainStore.save(pc, service: "PhoneBoxX", account: "active-pc")
            pairedPC = pc
            errorMessage = nil
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }

    func refresh() async {
        guard let pc = pairedPC else { return }
        let client = AgentClient(pc: pc)
        do {
            let data = try await client.rawRequest("/api/state")
            let object = try JSONDecoder().decode([String: JSONValue].self, from: data)
            snapshot = object
            isOnline = true
            errorMessage = nil
        } catch {
            isOnline = false
            errorMessage = error.localizedDescription
        }
        client.close()
    }

    func sendCommand(_ command: String) async {
        guard let pc = pairedPC else { return }
        let client = AgentClient(pc: pc)
        do {
            let body = try JSONSerialization.data(withJSONObject: ["command": command])
            _ = try await client.rawRequest("/api/controls/command", method: "POST", body: body)
        } catch { errorMessage = error.localizedDescription }
        client.close()
    }

    func forgetPC() {
        pairedPC = nil
        snapshot = [:]
        isOnline = false
        KeychainStore.delete(service: "PhoneBoxX", account: "active-pc")
    }
}
