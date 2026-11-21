import AppKit
import Foundation

// Disable buffering so logs flush immediately to disk/pipe
setbuf(stdout, nil)

print("=== Arc Mouse Event Monitor ===")
print("Move the mouse, scroll vertically/horizontally, and perform tap/click gestures.")
print("Events will be logged below in real-time. (Press Ctrl+C to stop)\n")

// Use NSApplication run loop for AppKit global monitors
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let mask: NSEvent.EventTypeMask = [
    .scrollWheel,
    .leftMouseDown,
    .leftMouseUp,
    .rightMouseDown,
    .rightMouseUp,
    .otherMouseDown,
    .otherMouseUp
]

var lastScrollTime: TimeInterval = 0

@_silgen_name("CGEventCopyIOHIDEvent")
func CGEventCopyIOHIDEvent(_ event: CGEvent) -> CFTypeRef?

@_silgen_name("IOHIDEventGetSenderID")
func IOHIDEventGetSenderID(_ event: CFTypeRef) -> UInt64

let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
    let now = Date().timeIntervalSince1970
    var senderID: UInt64 = 0
    if let cgEvent = event.cgEvent, let hidEvent = CGEventCopyIOHIDEvent(cgEvent) {
        senderID = IOHIDEventGetSenderID(hidEvent)
    }

    switch event.type {
    case .scrollWheel:
        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY
        let hasPrecise = event.hasPreciseScrollingDeltas
        let phase = event.phase.rawValue
        let momentumPhase = event.momentumPhase.rawValue
        
        let interval = lastScrollTime > 0 ? String(format: "%4.1fms", (now - lastScrollTime) * 1000) : " --- "
        lastScrollTime = now

        print(String(format: "[SCROLL %@] dy: %6.2f | dx: %6.2f | senderID: %llu | precise: %@ | phase: %d | momentum: %d",
                     interval, dy, dx, senderID, hasPrecise ? "YES" : "NO ", phase, momentumPhase))

    case .otherMouseDown:
        print("[BUTTON] OtherMouseDown - buttonNumber: \(event.buttonNumber) clickCount: \(event.clickCount)")
    case .otherMouseUp:
        print("[BUTTON] OtherMouseUp   - buttonNumber: \(event.buttonNumber)")
    case .rightMouseDown:
        print("[BUTTON] RightMouseDown")
    case .leftMouseDown:
        print("[BUTTON] LeftMouseDown")
    default:
        break
    }
}

if monitor == nil {
    print("[!] Warning: NSEvent.addGlobalMonitorForEvents returned nil.")
} else {
    print("[+] NSEvent Global Monitor registered with NSApplication.")
}

app.run()
