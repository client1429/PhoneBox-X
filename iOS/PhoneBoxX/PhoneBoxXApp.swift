import SwiftUI

@main
struct PhoneBoxXApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(.cyan)
        }
    }
}
