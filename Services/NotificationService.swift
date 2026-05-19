import Cocoa
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {
        requestPermission()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func sendLimitExceededNotification(appName: String, limitMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 使用时间超标"
        content.body = "\(appName) 已使用超过 \(limitMinutes) 分钟"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}