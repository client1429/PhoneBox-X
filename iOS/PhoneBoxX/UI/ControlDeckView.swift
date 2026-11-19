import SwiftUI

struct ControlDeckView: View {
    @EnvironmentObject private var store: AppStore
    private let actions: [(String, String)] = [
        ("Volume up", "volume_up"), ("Volume down", "volume_down"),
        ("Mute", "mute"), ("Play / Pause", "media_play_pause"),
        ("Next track", "media_next"), ("Previous track", "media_previous")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QUICK CONTROLS").font(.caption.monospaced()).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(actions, id: \.1) { title, command in
                    Button {
                        Task { await store.sendCommand(command) }
                    } label: {
                        Text(title).frame(maxWidth: .infinity, minHeight: 66)
                    }.buttonStyle(.bordered).tint(.cyan)
                }
            }
            Text("Lệnh được gửi tới PhoneBox Agent. Một số lệnh có thể cần bật quyền tương ứng trên PC.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}
