import Foundation
import SwiftUI

public struct ArcDebugEvent: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let category: EventCategory
    public let detail: String

    public enum EventCategory: String {
        case verticalScroll = "Scroll"
        case horizontalPan = "Pan"
        case button = "Button"
        case gesture = "Gesture"
        case device = "Device"

        public var color: Color {
            switch self {
            case .verticalScroll: return .blue
            case .horizontalPan: return .purple
            case .button: return .orange
            case .gesture: return .green
            case .device: return .gray
            }
        }

        public var icon: String {
            switch self {
            case .verticalScroll: return "arrow.up.and.down"
            case .horizontalPan: return "arrow.left.and.right"
            case .button: return "cursorarrow.click"
            case .gesture: return "hand.tap.fill"
            case .device: return "computermouse.fill"
            }
        }
    }
}

public final class ArcEventMonitor: ObservableObject {
    public static let shared = ArcEventMonitor()

    @Published public private(set) var events: [ArcDebugEvent] = []
    @Published public private(set) var lastVerticalDelta: Double = 0
    @Published public private(set) var lastHorizontalDelta: Double = 0
    @Published public private(set) var lastAction: String = "None"

    private let maxEvents = 150

    private init() {}

    public func record(category: ArcDebugEvent.EventCategory, detail: String) {
        let event = ArcDebugEvent(timestamp: Date(), category: category, detail: detail)
        DispatchQueue.main.async {
            self.events.append(event)
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }
        }
    }

    public func recordVertical(delta: Double) {
        let dir = delta > 0 ? "UP (+)" : "DOWN (-)"
        record(category: .verticalScroll, detail: String(format: "Delta: %+.1f (%@)", delta, dir))
        DispatchQueue.main.async {
            self.lastVerticalDelta = delta
        }
    }

    public func recordHorizontal(delta: Double) {
        let dir = delta > 0 ? "RIGHT (+)" : "LEFT (-)"
        record(category: .horizontalPan, detail: String(format: "Delta: %+.1f (%@)", delta, dir))
        DispatchQueue.main.async {
            self.lastHorizontalDelta = delta
        }
    }

    public func recordGesture(action: String) {
        record(category: .gesture, detail: "Triggered: \(action)")
        DispatchQueue.main.async {
            self.lastAction = action
        }
    }

    public func clear() {
        DispatchQueue.main.async {
            self.events.removeAll()
        }
    }
}
