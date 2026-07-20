import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                WTColor.cream.ignoresSafeArea()
                List {
                    Section {
                        HStack {
                            Text("Plan")
                            Spacer()
                            Text(entitlements.isPro ? "Pro" : "Free")
                                .foregroundStyle(entitlements.isPro ? WTColor.sage : WTColor.ink.opacity(0.6))
                        }
                        if !entitlements.isPro {
                            Button("Upgrade to Pro") { showPaywall = true }
                                .foregroundStyle(WTColor.coral)
                        } else {
                            Button("Restore Purchases") {
                                Task { await entitlements.restore() }
                            }
                        }
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(WTColor.ink.opacity(0.6))
                        }
                        Text("Whoseturn keeps all wheels, participants, and spin history stored only on this device. Nothing is uploaded anywhere.")
                            .font(WTFont.body(13))
                            .foregroundStyle(WTColor.ink.opacity(0.6))
                    }

                    Section("More Apps") {
                        ForEach(MoreApps.others(than: "Whoseturn - Chore Wheel")) { app in
                            Link(app.name, destination: app.url)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}
