import SwiftUI

struct TrackpadView: View {
    @EnvironmentObject private var store: AppStore
    @State private var lastPoint: CGPoint?
    @State private var moved = false

    var body: some View {
        VStack(spacing: 12) {
            Text("TRACKPAD").font(.caption.monospaced()).foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.06))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.draw").font(.largeTitle)
                        Text("Vuốt để di chuyển chuột").font(.callout)
                        Text("Chạm để click · Chạm hai ngón để click phải")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let last = lastPoint {
                            let dx = Double(value.location.x - last.x)
                            let dy = Double(value.location.y - last.y)
                            if abs(dx) + abs(dy) > 1 { moved = true; send(type: "move", dx: dx, dy: dy) }
                        }
                        lastPoint = value.location
                    }
                    .onEnded { _ in
                        if !moved { send(type: "click") }
                        lastPoint = nil
                        moved = false
                    })
                .simultaneousGesture(TapGesture(count: 2).onEnded { send(type: "rightClick") })
            HStack {
                Button("Left click") { send(type: "click") }.buttonStyle(.bordered)
                Button("Right click") { send(type: "rightClick") }.buttonStyle(.bordered)
            }
        }
    }

    private func send(type: String, dx: Double = 0, dy: Double = 0) {
        guard let pc = store.pairedPC else { return }
        Task {
            let client = AgentClient(pc: pc)
            let body = try? JSONSerialization.data(withJSONObject: ["type": type, "dx": dx, "dy": dy, "delta": 0])
            _ = try? await client.rawRequest("/api/trackpad", method: "POST", body: body)
            client.close()
        }
    }
}
