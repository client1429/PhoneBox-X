import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            Group {
                if store.pairedPC == nil {
                    PairingIntroView()
                } else {
                    DashboardView()
                }
            }
            .navigationTitle("PHONEBOX X")
            .toolbar {
                if store.pairedPC != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Circle().fill(store.isOnline ? .green : .orange).frame(width: 9, height: 9)
                    }
                }
            }
            .alert("PhoneBox X", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
    }
}
