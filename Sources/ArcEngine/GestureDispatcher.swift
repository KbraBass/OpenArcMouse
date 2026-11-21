import Cocoa
import CoreGraphics
import ArcCore

public struct GestureDispatcher {
    public static func dispatch(_ action: GestureAction) {
        switch action {
        case .missionControl:
            ArcEventMonitor.shared.recordGesture(action: "Mission Control")
            // Native application launch (instant & independent of shortcut preferences)
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.exposelauncher") ??
                         URL(string: "file:///System/Applications/Mission%20Control.app") {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
            } else {
                postHotkey(modifierKey: 59, actionKey: 126, modifierFlag: .maskControl)
            }

        case .appExpose:
            ArcEventMonitor.shared.recordGesture(action: "App Exposé")
            postHotkey(modifierKey: 59, actionKey: 125, modifierFlag: .maskControl)

        case .launchpad:
            let isModern = FileManager.default.fileExists(atPath: "/System/Applications/Apps.app")
            let label = isModern ? "Apps" : "Launchpad"
            ArcEventMonitor.shared.recordGesture(action: label)

            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.apps.launcher") ??
                         URL(string: "file:///System/Applications/Apps.app") ??
                         NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.launchpad.launcher") ??
                         URL(string: "file:///System/Applications/Launchpad.app") {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
            }

        case .switchSpaceLeft:
            ArcEventMonitor.shared.recordGesture(action: "Switch Desktop Left")
            switchSpace(isLeft: true)

        case .switchSpaceRight:
            ArcEventMonitor.shared.recordGesture(action: "Switch Desktop Right")
            switchSpace(isLeft: false)

        case .browserBack:
            ArcEventMonitor.shared.recordGesture(action: "Browser Back")
            postHotkey(modifierKey: 55, actionKey: 33, modifierFlag: .maskCommand)

        case .browserForward:
            ArcEventMonitor.shared.recordGesture(action: "Browser Forward")
            postHotkey(modifierKey: 55, actionKey: 30, modifierFlag: .maskCommand)

        case .middleClick:
            ArcEventMonitor.shared.recordGesture(action: "Middle Click (Button 3)")
            postMiddleClick()

        case .none:
            break
        }
    }

    /// Directly switches Desktop / Space on macOS with precise timed key transitions
    public static func switchSpace(isLeft: Bool) {
        let arrowKey: CGKeyCode = isLeft ? 123 : 124

        DispatchQueue.global(qos: .userInteractive).async {
            let source = CGEventSource(stateID: .hidSystemState)

            // 1. Press Ctrl key first (Key 59)
            if let ctrlDown = CGEvent(keyboardEventSource: source, virtualKey: 59, keyDown: true) {
                ctrlDown.flags = .maskControl
                ctrlDown.post(tap: .cghidEventTap)
            }

            // 2. 40ms delay (between 30 to 50 ms)
            usleep(40000)

            // 3. Press Arrow Key down (with Ctrl active)
            if let arrowDown = CGEvent(keyboardEventSource: source, virtualKey: arrowKey, keyDown: true) {
                arrowDown.flags = .maskControl
                arrowDown.post(tap: .cghidEventTap)
            }

            // 4. Keep pressing both for 60ms (at least 50 ms hold)
            usleep(60000)

            // 5. Release both simultaneously
            if let arrowUp = CGEvent(keyboardEventSource: source, virtualKey: arrowKey, keyDown: false) {
                arrowUp.flags = .maskControl
                arrowUp.post(tap: .cghidEventTap)
            }
            if let ctrlUp = CGEvent(keyboardEventSource: source, virtualKey: 59, keyDown: false) {
                ctrlUp.flags = []
                ctrlUp.post(tap: .cghidEventTap)
            }
        }
    }

    /// Posts native middle click (Button 3) to the foreground application
    public static func postMiddleClick() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        let source = CGEventSource(stateID: .combinedSessionState)

        if let down = CGEvent(mouseEventSource: source, mouseType: .otherMouseDown, mouseCursorPosition: loc, mouseButton: .center) {
            down.setIntegerValueField(.mouseEventButtonNumber, value: 2)
            down.setIntegerValueField(.eventSourceUserData, value: SmoothScrollEngine.magicEventTag)
            down.post(tap: .cgSessionEventTap)
        }

        usleep(15000) // 15ms hold

        if let up = CGEvent(mouseEventSource: source, mouseType: .otherMouseUp, mouseCursorPosition: loc, mouseButton: .center) {
            up.setIntegerValueField(.mouseEventButtonNumber, value: 2)
            up.setIntegerValueField(.eventSourceUserData, value: SmoothScrollEngine.magicEventTag)
            up.post(tap: .cgSessionEventTap)
        }
    }

    /// Posts hotkey transition with accurate timing to active user session (.cghidEventTap)
    private static func postHotkey(modifierKey: CGKeyCode, actionKey: CGKeyCode, modifierFlag: CGEventFlags) {
        DispatchQueue.global(qos: .userInteractive).async {
            let source = CGEventSource(stateID: .hidSystemState)

            // 1. Modifier Key Down
            if let modDown = CGEvent(keyboardEventSource: source, virtualKey: modifierKey, keyDown: true) {
                modDown.flags = modifierFlag
                modDown.post(tap: .cghidEventTap)
            }

            usleep(18000) // 18ms gap so WindowServer registers modifier

            // 2. Action Key Down (with modifier active)
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: actionKey, keyDown: true) {
                keyDown.flags = modifierFlag
                keyDown.post(tap: .cghidEventTap)
            }

            usleep(25000) // 25ms hold duration

            // 3. Action Key Up
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: actionKey, keyDown: false) {
                keyUp.flags = modifierFlag
                keyUp.post(tap: .cghidEventTap)
            }

            usleep(18000)

            // 4. Modifier Key Up
            if let modUp = CGEvent(keyboardEventSource: source, virtualKey: modifierKey, keyDown: false) {
                modUp.post(tap: .cghidEventTap)
            }
        }
    }
}
