import Foundation

/// Shared App Group configuration used by both the container app and the keyboard extension.
///
/// Replace the identifier with the App Group you registered in your Apple Developer account,
/// and keep it in sync with both `.entitlements` files and `project.yml`.
enum AppGroup {
    static let identifier = "group.com.yourname.keyboardX"

    /// App Group backed defaults. Falls back to `.standard` if the group container
    /// isn't available (e.g. Full Access disabled or entitlement missing).
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
