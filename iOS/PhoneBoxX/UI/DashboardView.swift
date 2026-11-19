import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab = 0
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.pairedPC?.name ?? "PC").font(.headline)
                    Text(store.isOnline ? "CONNECTED" : "DISCONNECTED")
                        .font(.caption2.monospaced()).foregroundStyle(store.isOnline ? .green : .orange)
                }
                Spacer()
                Button { Task { await store.refresh() } } label: {
                    Image(systemName: "arrow.clockwise").padding(10).background(.white.opacity(0.08), in: Circle())
                }
            }
            if selectedTab == 0 {
                SystemGrid(snapshot: store.snapshot)
            } else if selectedTab == 1 {
                ControlDeckView()
            } else {
                TrackpadView()
            }
            Spacer(minLength: 0)
            HStack {
                tab("square.grid.2x2", "System", 0)
                tab("slider.horizontal.3", "Controls", 1)
                tab("hand.draw", "Trackpad", 2)
            }.padding(8).background(.white.opacity(0.06), in: Capsule())
            Menu {
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await store.refresh() } }
                Button("Unpair PC", systemImage: "xmark.circle", role: .destructive) { store.forgetPC() }
            } label: {
                Label("PC settings", systemImage: "desktopcomputer").font(.caption)
            }
        }.padding()
        .task {
            await store.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                await store.refresh()
            }
        }
    }

    private func tab(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { selectedTab = index } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title).font(.caption2)
            }.frame(maxWidth: .infinity).foregroundStyle(selectedTab == index ? .cyan : .secondary)
        }
    }
}

struct SystemGrid: View {
    let snapshot: [String: JSONValue]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "CPU", value: find(["cpu", "cpuUsage", "cpuPercent"]), icon: "cpu")
            MetricCard(title: "MEMORY", value: find(["memory", "ram", "memoryUsage"]), icon: "memorychip")
            MetricCard(title: "GPU", value: find(["gpu", "gpuUsage"]), icon: "gpu")
            MetricCard(title: "UPTIME", value: find(["uptime"]), icon: "clock")
            MetricCard(title: "HOST", value: find(["hostname", "pc", "machineName"]), icon: "desktopcomputer")
            MetricCard(title: "OS", value: find(["os", "platform"]), icon: "laptopcomputer")
        }
    }
    private func find(_ keys: [String]) -> String {
        for key in keys {
            if let value = snapshot[key] {
                switch value {
                case .number(let n): return String(format: "%.0f%@", n, n <= 100 ? "%" : "")
                case .string(let s): return s
                default: break
                }
            }
        }
        return "—"
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundStyle(.cyan)
                Spacer()
                Text(title).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Text(value).font(.title3.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }.padding().frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
    }
}
