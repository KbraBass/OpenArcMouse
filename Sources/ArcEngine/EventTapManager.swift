import Foundation
import CoreGraphics
import ApplicationServices
import Cocoa
import ArcCore
import ArcHID

public final class EventTapManager: ObservableObject {
    public static let shared = EventTapManager()

    @Published public private(set) var isEnabled: Bool = false
    @Published public private(set) var hasAccessibilityPermission: Bool = false

    private var eventTapPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionPollTimer: Timer?

    private init() {
        checkPermission()
        startPermissionPolling()

        if hasAccessibilityPermission {
            startTap()
        } else {
            requestPermission()
        }
    }

    public func checkPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if self.hasAccessibilityPermission != trusted {
            DispatchQueue.main.async {
                self.hasAccessibilityPermission = trusted
            }
        }
    }

    public func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = trusted
        }
        if trusted {
            startTap()
        } else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func startPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkPermission()
            if self.hasAccessibilityPermission && !self.isEnabled {
                self.startTap()
            }
        }
    }

    public func startTap() {
        guard !isEnabled else { return }
        checkPermission()
        guard hasAccessibilityPermission else {
            return
        }

        // Tap scrollWheel and right-mouse events (for Button-2 modifier gestures)
        let mask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue) |
                                (1 << CGEventType.rightMouseDown.rawValue) |
                                (1 << CGEventType.rightMouseUp.rawValue)

        let context = Unmanaged.passUnretained(self).toOpaque()

        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: context
        ) else {
            return
        }

        self.eventTapPort = port
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        self.isEnabled = true
    }

    public func stopTap() {
        guard isEnabled, let port = eventTapPort else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        self.eventTapPort = nil
        self.runLoopSource = nil
        self.isEnabled = false
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()
            manager.startTap()
        }
        return Unmanaged.passUnretained(event)
    }

    // Pass through our own synthetic events immediately (e.g. synthetic right click or spaces swipe)
    if SmoothScrollEngine.isSyntheticEvent(event) {
        return Unmanaged.passUnretained(event)
    }

    // Only process events originating strictly from the Microsoft Arc Mouse
    guard DeviceWatcher.shared.isArcMouseEvent(event) else {
        return Unmanaged.passUnretained(event)
    }

    // If Test Mode is active (Mute Event Synthesis), pass everything through
    if ArcConfig.shared.isSeizureTestModeEnabled {
        return Unmanaged.passUnretained(event)
    }

    switch type {
    case .rightMouseDown:
        // Record Button 2 state and withhold rightMouseDown so WindowServer doesn't lock out hotkeys
        GestureEngine.shared.isButton2Down = true
        GestureEngine.shared.didPerformGesture = false
        return nil // Suppress rightMouseDown until released or gesture performed

    case .rightMouseUp:
        GestureEngine.shared.isButton2Down = false
        if GestureEngine.shared.didPerformGesture {
            // A Button-2 gesture was performed (space switch or app launch) -> suppress context menu
            GestureEngine.shared.didPerformGesture = false
            return nil
        } else {
            // Standard Right Click: dispatch synthetic right click
            let loc = event.location
            let source = CGEventSource(stateID: .combinedSessionState)
            if let down = CGEvent(mouseEventSource: source, mouseType: .rightMouseDown, mouseCursorPosition: loc, mouseButton: .right) {
                down.setIntegerValueField(.eventSourceUserData, value: SmoothScrollEngine.magicEventTag)
                down.post(tap: .cgSessionEventTap)
            }
            if let up = CGEvent(mouseEventSource: source, mouseType: .rightMouseUp, mouseCursorPosition: loc, mouseButton: .right) {
                up.setIntegerValueField(.eventSourceUserData, value: SmoothScrollEngine.magicEventTag)
                up.post(tap: .cgSessionEventTap)
            }
            return nil
        }

    case .scrollWheel:
        let intDx = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
        let fixedDx = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        let rawDx = fixedDx != 0 ? fixedDx : Double(intDx)

        let intDy = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let fixedDy = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let rawDy = fixedDy != 0 ? fixedDy : Double(intDy)

        // 1. If Button 2 is held: check for horizontal gesture (Switch Desktops)
        if GestureEngine.shared.handleHorizontalDelta(rawDx) {
            return nil // Suppress scroll event completely when switching desktops
        }

        // 2. If Button 2 is held: check for vertical gesture (Mission Control / Apps)
        if GestureEngine.shared.handleVerticalDelta(rawDy) {
            return nil // Suppress scroll event completely when triggering vertical gesture
        }

        // 3. Normal Scrolling (Button 2 not held): Invert scroll in-place for Natural Scrolling
        // Passes directly to native macOS display pipeline for maximum smoothness
        if ArcConfig.shared.naturalScroll {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -intDy)
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -intDx)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedDy)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fixedDx)
            let pointDy = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
            let pointDx = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointDy)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -pointDx)
            ArcEventMonitor.shared.recordVertical(delta: Double(-intDy))
        } else {
            ArcEventMonitor.shared.recordVertical(delta: Double(intDy))
        }

        return Unmanaged.passUnretained(event)

    default:
        break
    }

    return Unmanaged.passUnretained(event)
}
