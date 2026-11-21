import Foundation

public enum GestureAction: String, CaseIterable, Codable, Identifiable {
    case missionControl = "Mission Control"
    case appExpose = "App Exposé"
    case launchpad = "Apps"
    case switchSpaceLeft = "Switch Space Left"
    case switchSpaceRight = "Switch Space Right"
    case browserBack = "Browser Back"
    case browserForward = "Browser Forward"
    case middleClick = "Middle Click"
    case none = "None"

    public var id: String { rawValue }

    public var displayName: String {
        if self == .launchpad {
            return FileManager.default.fileExists(atPath: "/System/Applications/Apps.app") ? "Apps" : "Launchpad"
        }
        return rawValue
    }

    public var iconName: String {
        switch self {
        case .missionControl: return "rectangle.3.group"
        case .appExpose: return "rectangle.grid.2x2"
        case .launchpad: return "square.grid.3x3.fill"
        case .switchSpaceLeft: return "arrow.left.to.line"
        case .switchSpaceRight: return "arrow.right.to.line"
        case .browserBack: return "arrow.left"
        case .browserForward: return "arrow.right"
        case .middleClick: return "cursorarrow.click.2"
        case .none: return "slash.circle"
        }
    }
}
