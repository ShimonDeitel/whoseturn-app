import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: WhoseturnStore
    @State private var showSettings = false

    var body: some View {
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
    }
}
