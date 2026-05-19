import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        // Start monitoring service
        MonitoringService.shared.start()

        // Show main window
        showMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MonitoringService.shared.stop()
    }

    func showMainWindow() {
        let contentView = ContentView()

        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        mainWindow?.title = "FocusGuard - 软件使用监控"
        mainWindow?.contentView = NSHostingView(rootView: contentView)
        mainWindow?.center()
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func showMainWindow(_ sender: Any?) {
        if mainWindow == nil {
            showMainWindow()
        } else {
            mainWindow?.makeKeyAndOrderFront(nil)
        }
    }
}