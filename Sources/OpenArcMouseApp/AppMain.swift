import SwiftUI
import AppKit
import ArcCore
import ArcEngine
import ArcHID

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private var monitorWindow: NSWindow?
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize device watcher, event tap, and hardware monitor
        _ = DeviceWatcher.shared
        _ = EventTapManager.shared
        ArcSeizedDeviceDriver.shared.start()

        // Hide dock icon so it runs purely as a menu bar extra
        NSApp.setActivationPolicy(.accessory)
    }

    func showAboutWindow() {
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "About OpenArcMouse"
        window.contentView = NSHostingView(rootView: AboutView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.aboutWindow = window
    }

    func showMonitorWindow() {
        if let window = monitorWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "OpenArcMouse - Live Event Monitor"
        window.contentView = NSHostingView(rootView: EventMonitorWindowView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.monitorWindow = window
    }

    func showSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 530),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "OpenArcMouse Preferences"
        window.contentView = NSHostingView(rootView: SettingsWindowView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow = window
    }
}

@main
struct OpenArcMouseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("OpenArcMouse", systemImage: "computermouse.fill") {
            MenuBarContentView(openSettings: {
                appDelegate.showSettingsWindow()
            }, openMonitor: {
                appDelegate.showMonitorWindow()
            }, openAbout: {
                appDelegate.showAboutWindow()
            })
        }
        .menuBarExtraStyle(.window)
    }
}
