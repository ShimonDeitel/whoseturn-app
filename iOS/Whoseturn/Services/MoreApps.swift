import Foundation

/// Cross-promotion: every app in this shared-design-language batch lists the
/// others in Settings, so someone who downloads one discovers (and hopefully
/// buys Pro on) the rest of the portfolio.
struct MoreAppsEntry: Identifiable {
    var id: String { name }
    let name: String
    let appStoreID: String
    var url: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)")! }
}

enum MoreApps {
    static let all: [MoreAppsEntry] = [
        MoreAppsEntry(name: "Whoseturn - Chore Wheel", appStoreID: "6792599108"),
        MoreAppsEntry(name: "Ripely - Ripeness Tracker", appStoreID: "6792604468"),
        MoreAppsEntry(name: "Boxed - Storage Finder", appStoreID: "6792592402"),
        MoreAppsEntry(name: "Shielded - Warranty Tracker", appStoreID: "6792636563"),
        MoreAppsEntry(name: "Openlater - Time Capsule", appStoreID: "6792560760"),
        MoreAppsEntry(name: "Rulehive - Board Game Rules", appStoreID: "6792561286"),
        MoreAppsEntry(name: "Sprinkle - Tooth Fairy Tracker", appStoreID: "6792651467"),
        MoreAppsEntry(name: "Curing - Firewood Tracker", appStoreID: "6792659038"),
    ]

    static func others(than name: String) -> [MoreAppsEntry] {
        all.filter { $0.name != name }
    }
}
