import SwiftUI

/// Ad layer. Real network (AdMob) requires the GoogleMobileAds SDK + an
/// AdMob account, which needs an owner login — so v1 ships with a
/// self-promo house-ad banner (cross-promotes the portfolio, fully
/// App-Store-legal) shown only to free-tier users. Swapping in AdMob later
/// means replacing `HouseBannerView` with a `GADBannerView` wrapper; the
/// `adsEnabled` gate and placement stay the same.
enum AdsManager {
    static func adsEnabled(isPro: Bool) -> Bool { !isPro }
}

/// House banner shown at the bottom of the wheel list for free users.
struct HouseBannerView: View {
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(WTColor.marigold.opacity(0.25))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(WTColor.marigold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Ad").font(WTFont.body(11)).foregroundStyle(WTColor.ink.opacity(0.5))
                Text("Remove ads with Whoseturn Pro").font(WTFont.heading(14)).foregroundStyle(WTColor.ink)
            }
            Spacer()
        }
        .padding(12)
        .background(WTColor.sand)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }
}
