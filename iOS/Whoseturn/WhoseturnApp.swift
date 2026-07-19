import SwiftUI

@main
struct WhoseturnApp: App {
    @StateObject private var entitlements: EntitlementsStore
    @StateObject private var store: WhoseturnStore

    init() {
        let entitlementsStore = EntitlementsStore()
        _entitlements = StateObject(wrappedValue: entitlementsStore)
        _store = StateObject(wrappedValue: WhoseturnStore(entitlements: entitlementsStore))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(entitlements)
                .preferredColorScheme(.light)
        }
    }
}
