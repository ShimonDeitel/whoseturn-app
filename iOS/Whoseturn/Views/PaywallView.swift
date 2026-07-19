import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                WTColor.cream.ignoresSafeArea()
                VStack(spacing: 22) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(WTColor.marigold)
                        .padding(.top, 12)

                    Text("Whoseturn Pro")
                        .font(WTFont.title(26))
                        .foregroundStyle(WTColor.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow(icon: "circle.grid.3x3.fill", text: "Unlimited wheels")
                        featureRow(icon: "person.3.fill", text: "Unlimited participants per wheel")
                        featureRow(icon: "paintpalette.fill", text: "Custom categories and icons per wheel")
                        featureRow(icon: "chart.bar.fill", text: "Spin history and fairness stats")
                    }
                    .padding()
                    .background(WTColor.sand, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Spacer()

                    Button {
                        Task {
                            let success = await entitlements.purchase()
                            if success { dismiss() }
                        }
                    } label: {
                        Text(entitlements.purchaseInFlight ? "Processing..." : "Subscribe — \(entitlements.displayPrice)/month")
                    }
                    .buttonStyle(WTButtonStyle(background: WTColor.coral))
                    .disabled(entitlements.purchaseInFlight)

                    Text("Auto-renewable subscription, billed monthly to your Apple ID. Manage or cancel anytime in Settings.")
                        .font(WTFont.body(12))
                        .foregroundStyle(WTColor.ink.opacity(0.55))
                        .multilineTextAlignment(.center)

                    Button("Restore Purchases") {
                        Task { await entitlements.restore() }
                    }
                    .font(WTFont.body(14))
                    .foregroundStyle(WTColor.plum)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(WTColor.sage)
                .frame(width: 24)
            Text(text)
                .font(WTFont.body(15))
                .foregroundStyle(WTColor.ink)
        }
    }
}
