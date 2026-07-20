import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: WhoseturnStore
    @State private var showSettings = false
    #if DEBUG
    @State private var path: [UUID] = []
    #endif

    var body: some View {
        #if DEBUG
        NavigationStack(path: $path) {
            WheelListView()
                .navigationTitle("Whoseturn")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(WTColor.plum)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .navigationDestination(for: UUID.self) { wheelID in
                    WheelDetailView(wheelID: wheelID)
                }
        }
        .tint(WTColor.coral)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear {
            if ProcessInfo.processInfo.environment["WHOSETURN_SCREENSHOT_DETAIL"] == "1",
               let first = store.data.wheels.first {
                path = [first.id]
            }
        }
        #else
        NavigationStack {
            WheelListView()
                .navigationTitle("Whoseturn")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(WTColor.plum)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
        }
        .tint(WTColor.coral)
        .sheet(isPresented: $showSettings) { SettingsView() }
        #endif
    }
}
