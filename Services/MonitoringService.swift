import Cocoa

class MonitoringService {
    static let shared = MonitoringService()

    private var timer: Timer?
    private var lastActiveApp: NSRunningApplication?
    private var lastCheckTime: Date?

    private init() {}

    func start() {
        guard timer == nil else { return }

        lastCheckTime = Date()
        lastActiveApp = NSWorkspace.shared.frontmostApplication

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkActiveApp()
        }

        // Initial check
        checkActiveApp()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkActiveApp() {
        guard let currentApp = NSWorkspace.shared.frontmostApplication else { return }

        let now = Date()
        let bundleId = currentApp.bundleIdentifier ?? "unknown"
        let appName = currentApp.localizedName ?? "Unknown"

        // Record usage if app changed or after interval
        if let lastApp = lastActiveApp, let lastTime = lastCheckTime {
            let duration = Int(now.timeIntervalSince(lastTime))
            if lastApp.bundleIdentifier == bundleId {
                // Same app, accumulate duration
                DatabaseManager.shared.updateUsageDuration(
                    bundleId: lastApp.bundleIdentifier ?? "",
                    duration: duration
                )
            } else {
                // App changed, record previous app and start new
                DatabaseManager.shared.insertUsageRecord(
                    bundleId: lastApp.bundleIdentifier ?? "",
                    appName: lastApp.localizedName ?? "Unknown",
                    duration: duration
                )

                // Check limit for the app we just left
                checkLimitAndNotify(
                    bundleId: lastApp.bundleIdentifier ?? "",
                    appName: lastApp.localizedName ?? "Unknown"
                )
            }
        }

        lastActiveApp = currentApp
        lastCheckTime = now

        // Post notification for UI update
        NotificationCenter.default.post(name: .usageUpdated, object: nil)
    }

    private func checkLimitAndNotify(bundleId: String, appName: String) {
        guard let limitSeconds = DatabaseManager.shared.getLimit(for: bundleId) else { return }

        let todayRecords = DatabaseManager.shared.getTodayUsage()
        let totalUsage = todayRecords
            .filter { $0.appBundleId == bundleId }
            .reduce(0) { $0 + $1.durationSeconds }

        if totalUsage >= limitSeconds {
            NotificationService.shared.sendLimitExceededNotification(
                appName: appName,
                limitMinutes: limitSeconds / 60
            )
        }
    }
}

extension Notification.Name {
    static let usageUpdated = Notification.Name("usageUpdated")
}