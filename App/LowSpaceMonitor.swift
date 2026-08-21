import Foundation
import UserNotifications
import OSLog

private let log = Logger(subsystem: "com.erickmenezes.DiskUsage", category: "lowspace")

/// Watches the boot volume and posts a notification when free space crosses
/// below the configured threshold.
///
/// Scope note: this only runs while the host app is running. A true background
/// watcher would need a login item or LaunchAgent — deliberately out of scope.
@MainActor
final class LowSpaceMonitor: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var lastCheck: Date?
    @Published private(set) var currentFreePercent: Int?
    @Published private(set) var authorized = false

    private var timer: Timer?
    private let interval: TimeInterval = 5 * 60

    /// Re-arm only after free space recovers this far above the threshold, so a
    /// volume hovering on the boundary cannot fire repeatedly.
    private let hysteresisPoints = 2

    func start() {
        // Without a delegate, macOS silently drops the banner and sound for any
        // notification posted while this app is frontmost -- which is always the
        // case here, since the first check runs on launch. It would still land in
        // Notification Center, which is exactly the "no float, no sound" symptom.
        UNUserNotificationCenter.current().delegate = self
        Task { await requestAuthorization() }
        check()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func requestAuthorization() async {
        do {
            authorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            log.error("notification authorization failed: \(error.localizedDescription, privacy: .public)")
            authorized = false
        }
    }

    func check() {
        lastCheck = .now
        guard let boot = DiskReader.bootVolume() else {
            log.error("check: boot volume unreadable")
            return
        }

        let freePercent = Int(((1 - boot.usedFraction) * 100).rounded())
        currentFreePercent = freePercent

        let threshold = AppGroup.thresholdPercent
        let wasBelow = AppGroup.defaults.bool(forKey: AppGroup.Key.isBelowThreshold)
        let isBelow = freePercent <= threshold
        log.notice("check: free=\(freePercent)% threshold=\(threshold)% enabled=\(AppGroup.alertsEnabled) wasBelow=\(wasBelow) isBelow=\(isBelow) shared=\(AppGroup.isShared)")

        guard AppGroup.alertsEnabled else { return }

        if isBelow && !wasBelow {
            AppGroup.defaults.set(true, forKey: AppGroup.Key.isBelowThreshold)
            AppGroup.defaults.set(Date(), forKey: AppGroup.Key.lastAlertDate)
            notify(volume: boot, freePercent: freePercent)
        } else if !isBelow && wasBelow && freePercent >= threshold + hysteresisPoints {
            // Recovered with margin — arm the next crossing.
            AppGroup.defaults.set(false, forKey: AppGroup.Key.isBelowThreshold)
            log.notice("check: recovered to \(freePercent)% free, re-armed")
        }
    }

    /// Fire immediately regardless of threshold state — used by the Test button.
    func sendTestNotification() {
        guard let boot = DiskReader.bootVolume() else { return }
        notify(volume: boot, freePercent: Int(((1 - boot.usedFraction) * 100).rounded()), isTest: true)
    }

    private func notify(volume: DiskInfo, freePercent: Int, isTest: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = isTest ? "Disk Usage — test alert" : "Low disk space"
        content.body = "\(volume.volumeName) has \(DiskInfo.fmt(volume.availableBytes)) free (\(freePercent)%) of \(DiskInfo.fmt(volume.totalBytes))."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: isTest ? "lowspace.test.\(UUID().uuidString)" : "lowspace.\(volume.id)",
            content: content,
            trigger: nil       // deliver now
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                log.error("notify failed: \(error.localizedDescription, privacy: .public)")
            } else {
                log.notice("notify posted for \(volume.volumeName, privacy: .public) at \(freePercent)% free")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
