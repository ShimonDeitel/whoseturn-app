import SwiftUI

struct WheelListView: View {
    @EnvironmentObject private var store: WhoseturnStore
    @EnvironmentObject private var entitlements: EntitlementsStore
    @State private var showAddWheel = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            WTColor.cream.ignoresSafeArea()

            if store.data.wheels.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.data.wheels) { wheel in
                        NavigationLink {
                            WheelDetailView(wheelID: wheel.id)
                        } label: {
                            wheelRow(wheel)
                        }
                        .listRowBackground(WTColor.cream)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteWheel(store.data.wheels[index])
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if AdsManager.adsEnabled(isPro: entitlements.isPro) {
                    HouseBannerView()
                }
                Button {
                    if store.canAddWheel {
                        showAddWheel = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("New Wheel", systemImage: "plus.circle.fill")
                }
                .buttonStyle(WTButtonStyle(background: WTColor.marigold))
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showAddWheel) { AddWheelSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func wheelRow(_ wheel: Wheel) -> some View {
        HStack(spacing: 14) {
            Image(systemName: wheel.iconSymbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(WTColor.sage, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(wheel.name)
                    .font(WTFont.heading(18))
                    .foregroundStyle(WTColor.ink)
                Text("\(wheel.participants.count) participant\(wheel.participants.count == 1 ? "" : "s")")
                    .font(WTFont.body(13))
                    .foregroundStyle(WTColor.ink.opacity(0.6))
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(WTColor.coral)
            Text("No wheels yet")
                .font(WTFont.title(22))
                .foregroundStyle(WTColor.ink)
            Text("Create a wheel for any chore or decision your household needs to rotate fairly.")
                .font(WTFont.body(15))
                .foregroundStyle(WTColor.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 60)
    }
}
