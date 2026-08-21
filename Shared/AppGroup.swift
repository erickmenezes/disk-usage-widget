import Foundation

/// Shared container between the host app and the widget extension.
/// Both targets must carry the matching com.apple.security.application-groups
/// entitlement or `defaults` silently falls back to standard UserDefaults.
enum AppGroup {
    static let identifier = "group.com.erickmenezes.DiskUsage"

    /// Nil only if the entitlement is missing/mismatched — callers fall back to
    /// .standard so the app still works rather than losing settings silently.
    static let defaults: UserDefaults = UserDefaults(suiteName: identifier) ?? .standard

    static var isShared: Bool { UserDefaults(suiteName: identifier) != nil }

    enum Key {
        static let alertsEnabled = "lowSpace.alertsEnabled"
        static let thresholdPercent = "lowSpace.thresholdPercent"
        /// Tracks whether we are currently in the "low" state, so an alert
        /// fires on the crossing rather than on every check.
        static let isBelowThreshold = "lowSpace.isBelowThreshold"
        static let lastAlertDate = "lowSpace.lastAlertDate"
    }

    /// Free-space percentage at or below which an alert fires.
    static var thresholdPercent: Int {
        get {
            let v = defaults.integer(forKey: Key.thresholdPercent)
            return v == 0 ? 10 : v      // 0 means "never set"
        }
        set { defaults.set(newValue, forKey: Key.thresholdPercent) }
    }

    static var alertsEnabled: Bool {
        get { defaults.bool(forKey: Key.alertsEnabled) }
        set { defaults.set(newValue, forKey: Key.alertsEnabled) }
    }
}
