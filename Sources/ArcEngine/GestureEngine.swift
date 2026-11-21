import Foundation
import CoreGraphics
import ArcCore

public final class GestureEngine {
    public static let shared = GestureEngine()

    // Button states tracked from hardware HID and EventTap
    public var isButton2Down: Bool = false
    public var isButton3Down: Bool = false
    public var didPerformGesture: Bool = false

    public var isModifierButtonHeld: Bool {
        return isButton2Down || isButton3Down
    }

    // Unified Gesture Cooldown (Inertia Filter)
    private var lastGestureTriggerTime: TimeInterval = 0

    // Horizontal flick (Button-2 + Side swipe -> Toggle Desktops)
    private var horizontalAccumulator: Double = 0
    private var horizontalStartTime: TimeInterval = 0
    private let horizontalFlickThreshold: Double = 1.8
    private let flickMaxDuration: TimeInterval = 0.45

    // Vertical swipe (Button-2 + Vertical swipe -> Mission Control / Apps)
    private var verticalAccumulator: Double = 0
    private var verticalStartTime: TimeInterval = 0
    private let verticalFlickThreshold: Double = 2.0
    private let verticalFlickMaxDuration: TimeInterval = 0.45

    // 3-Finger Button Click State (Double Click -> Mission Control)
    // Single click passes through natively as Middle Click without delay
    private var lastClickTime: TimeInterval = 0
    private let doubleClickThreshold: TimeInterval = 0.38

    private init() {}

    /// Hardware-level trigger for 3-finger physical click (Usage 3 on Microsoft Arc Mouse)
    public func handleThreeFingerClick() {
        let now = Date().timeIntervalSince1970
        let timeSinceLastClick = now - lastClickTime

        if timeSinceLastClick < doubleClickThreshold && timeSinceLastClick > 0.06 {
            // DOUBLE CLICK detected!
            lastClickTime = 0 // Reset so a 3rd click doesn't trigger another action

            let action = ArcConfig.shared.threeFingerDoubleTapAction
            ArcEventMonitor.shared.recordGesture(action: "3-Finger Double-Click -> \(action.displayName)")
            GestureDispatcher.dispatch(action)
        } else {
            // First click: record timestamp. Single click passes through natively as standard Middle Click!
            lastClickTime = now
        }
    }

    /// Process horizontal scroll deltas (Button-2 + Side scroll -> Toggle Desktops / Spaces)
    /// Returns `true` if recognized as a side swipe gesture or if button is held to suppress scrolling.
    public func handleHorizontalDelta(_ dx: Double) -> Bool {
        let config = ArcConfig.shared
        guard config.horizontalFlickEnabled else { return false }

        // Require Button 2 (or Button 3) to be held down for Desktop switching!
        guard isModifierButtonHeld else {
            return false // Regular horizontal scrolling when no button is held!
        }

        let now = Date().timeIntervalSince1970
        let cooldown = max(0.1, config.gestureCooldownMs / 1000.0)
        if now - lastGestureTriggerTime < cooldown {
            // In cooldown: ignore inertia ticks and suppress scrolling
            horizontalAccumulator = 0
            return true
        }

        if abs(dx) < 0.15 { return false }

        // Reset window if duration exceeded
        if now - horizontalStartTime > flickMaxDuration {
            horizontalAccumulator = 0
            horizontalStartTime = now
        }

        horizontalAccumulator += dx

        if abs(horizontalAccumulator) >= horizontalFlickThreshold {
            let isLeftFlick = horizontalAccumulator < 0
            let action = isLeftFlick ? config.flickLeftAction : config.flickRightAction

            didPerformGesture = true
            GestureDispatcher.dispatch(action)
            lastGestureTriggerTime = now
            horizontalAccumulator = 0
            verticalAccumulator = 0
            return true
        }

        return true // Suppress raw horizontal scroll deltas while button is held
    }

    /// Process vertical scroll deltas (Button-2 + Vertical scroll -> Mission Control / Apps)
    public func handleVerticalDelta(_ dy: Double) -> Bool {
        // Require Button 2 (or Button 3) to be held down!
        guard isModifierButtonHeld else {
            return false // Normal vertical scrolling when no button is held!
        }

        let config = ArcConfig.shared
        let now = Date().timeIntervalSince1970
        let cooldown = max(0.1, config.gestureCooldownMs / 1000.0)
        if now - lastGestureTriggerTime < cooldown {
            // In cooldown: ignore momentum ticks so Mission Control doesn't toggle repeatedly!
            verticalAccumulator = 0
            return true
        }

        if abs(dy) < 0.15 { return false }

        // Reset window if duration exceeded
        if now - verticalStartTime > verticalFlickMaxDuration {
            verticalAccumulator = 0
            verticalStartTime = now
        }

        verticalAccumulator += dy

        // Swipe UP (dy > 0): Mission Control
        if verticalAccumulator >= verticalFlickThreshold && config.swipeUpEnabled {
            didPerformGesture = true
            GestureDispatcher.dispatch(config.swipeUpAction)
            lastGestureTriggerTime = now
            verticalAccumulator = 0
            horizontalAccumulator = 0
            return true
        }

        // Swipe DOWN (dy < 0): Apps / App Drawer
        if verticalAccumulator <= -verticalFlickThreshold && config.swipeDownEnabled {
            didPerformGesture = true
            GestureDispatcher.dispatch(config.swipeDownAction)
            lastGestureTriggerTime = now
            verticalAccumulator = 0
            horizontalAccumulator = 0
            return true
        }

        return true // Suppress raw vertical scroll deltas while button is held
    }
}
