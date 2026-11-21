import Foundation
import CoreGraphics
import AppKit
import ArcCore

public final class ArcPointerEngine {
    public static let shared = ArcPointerEngine()

    private var isLeftDown = false
    private var isRightDown = false
    private var lastLeftClickTime: TimeInterval = 0
    private var leftClickCount: Int64 = 0

    private init() {}

    public func handleDeltaX(_ dx: Int) {
        guard dx != 0 else { return }
        moveCursor(deltaX: Double(dx), deltaY: 0)
    }

    public func handleDeltaY(_ dy: Int) {
        guard dy != 0 else { return }
        moveCursor(deltaX: 0, deltaY: Double(dy))
    }

    private func moveCursor(deltaX: Double, deltaY: Double) {
        guard let currentLoc = CGEvent(source: nil)?.location else { return }

        // Standard acceleration curve
        let speed = sqrt(deltaX * deltaX + deltaY * deltaY)
        let accel = 1.0 + min(3.0, pow(speed, 1.2) * 0.04)

        let targetX = currentLoc.x + (deltaX * accel)
        let targetY = currentLoc.y + (deltaY * accel)
        let newLocation = CGPoint(x: targetX, y: targetY)

        let eventType: CGEventType
        let mouseButton: CGMouseButton

        if isLeftDown {
            eventType = .leftMouseDragged
            mouseButton = .left
        } else if isRightDown {
            eventType = .rightMouseDragged
            mouseButton = .right
        } else {
            eventType = .mouseMoved
            mouseButton = .left
        }

        if let event = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: newLocation, mouseButton: mouseButton) {
            event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX * accel))
            event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY * accel))
            event.post(tap: .cgSessionEventTap)
        }
    }

    public func handleButton(_ button: Int, isDown: Bool) {
        guard let location = CGEvent(source: nil)?.location else { return }

        switch button {
        case 1: // Left Button
            isLeftDown = isDown
            let now = Date().timeIntervalSince1970
            if isDown {
                if now - lastLeftClickTime < NSEvent.doubleClickInterval {
                    leftClickCount += 1
                } else {
                    leftClickCount = 1
                }
                lastLeftClickTime = now
            }
            let type: CGEventType = isDown ? .leftMouseDown : .leftMouseUp
            if let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: location, mouseButton: .left) {
                event.setIntegerValueField(.mouseEventClickState, value: leftClickCount)
                event.post(tap: .cgSessionEventTap)
            }

        case 2: // Right Button
            isRightDown = isDown
            let type: CGEventType = isDown ? .rightMouseDown : .rightMouseUp
            if let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: location, mouseButton: .right) {
                event.post(tap: .cgSessionEventTap)
            }

        default:
            break
        }
    }
}
