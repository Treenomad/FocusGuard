import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        // Start monitoring service
        MonitoringService.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MonitoringService.shared.stop()
    }
}