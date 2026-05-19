import Cocoa
import SwiftUI

class StatusBarController {
    var statusItem: NSStatusItem
    var timer: Timer?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "FocusGuard")
        }

        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()

        // Title
        let titleItem = NSMenuItem(title: "FocusGuard", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Today's usage header
        let headerItem = NSMenuItem(title: "今日使用", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Top apps
        let topApps = DatabaseManager.shared.getTopAppsToday(limit: 5)
        if topApps.isEmpty {
            let emptyItem = NSMenuItem(title: "  暂无数据", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (appName, duration) in topApps {
                let minutes = duration / 60
                let item = NSMenuItem(title: "  \(appName): \(minutes)m", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Open main window
        let openItem = NSMenuItem(title: "打开主界面", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func openMainWindow() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showMainWindow()
        }
    }
}