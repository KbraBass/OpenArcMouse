import Foundation

public final class ArcConfig: ObservableObject {
    public static let shared = ArcConfig()

    private let defaults = UserDefaults.standard

    // Keys
    private let kConfigVersion = "arc_config_version_v5"
    private let kSmoothScrollEnabled = "arc_smooth_scroll_enabled"
    private let kScrollSpeed = "arc_scroll_speed"
    private let kMomentumDecay = "arc_momentum_decay"
    private let kNaturalScroll = "arc_natural_scroll"
    private let kHorizontalFlickEnabled = "arc_horizontal_flick_enabled"
    private let kFlickLeftAction = "arc_flick_left_action"
    private let kFlickRightAction = "arc_flick_right_action"
    private let kSwipeUpEnabled = "arc_swipe_up_enabled"
    private let kSwipeUpAction = "arc_swipe_up_action"
    private let kSwipeDownEnabled = "arc_swipe_down_enabled"
    private let kSwipeDownAction = "arc_swipe_down_action"
    private let kGestureCooldownMs = "arc_gesture_cooldown_ms"
    private let kThreeFingerTapAction = "arc_three_finger_tap_action"
    private let kThreeFingerDoubleTapAction = "arc_three_finger_double_tap_action"
    private let kLaunchAtLogin = "arc_launch_at_login"
    private let kCheckForUpdatesOnLaunch = "arc_check_for_updates_on_launch"
    private let kHasPromptedForUpdates = "arc_has_prompted_for_updates"
    private let kSeizureTestModeEnabled = "arc_seizure_test_mode_enabled"

    @Published public var checkForUpdatesOnLaunch: Bool {
        didSet { defaults.set(checkForUpdatesOnLaunch, forKey: kCheckForUpdatesOnLaunch) }
    }

    @Published public var hasPromptedForUpdates: Bool {
        didSet { defaults.set(hasPromptedForUpdates, forKey: kHasPromptedForUpdates) }
    }

    @Published public var isSeizureTestModeEnabled: Bool {
        didSet { defaults.set(isSeizureTestModeEnabled, forKey: kSeizureTestModeEnabled) }
    }

    @Published public var smoothScrollEnabled: Bool {
        didSet { defaults.set(smoothScrollEnabled, forKey: kSmoothScrollEnabled) }
    }

    @Published public var scrollSpeed: Double {
        didSet { defaults.set(scrollSpeed, forKey: kScrollSpeed) }
    }

    @Published public var momentumDecay: Double {
        didSet { defaults.set(momentumDecay, forKey: kMomentumDecay) }
    }

    @Published public var naturalScroll: Bool {
        didSet { defaults.set(naturalScroll, forKey: kNaturalScroll) }
    }

    @Published public var horizontalFlickEnabled: Bool {
        didSet { defaults.set(horizontalFlickEnabled, forKey: kHorizontalFlickEnabled) }
    }

    @Published public var flickLeftAction: GestureAction {
        didSet { defaults.set(flickLeftAction.rawValue, forKey: kFlickLeftAction) }
    }

    @Published public var flickRightAction: GestureAction {
        didSet { defaults.set(flickRightAction.rawValue, forKey: kFlickRightAction) }
    }

    @Published public var swipeUpEnabled: Bool {
        didSet { defaults.set(swipeUpEnabled, forKey: kSwipeUpEnabled) }
    }

    @Published public var swipeUpAction: GestureAction {
        didSet { defaults.set(swipeUpAction.rawValue, forKey: kSwipeUpAction) }
    }

    @Published public var swipeDownEnabled: Bool {
        didSet { defaults.set(swipeDownEnabled, forKey: kSwipeDownEnabled) }
    }

    @Published public var swipeDownAction: GestureAction {
        didSet { defaults.set(swipeDownAction.rawValue, forKey: kSwipeDownAction) }
    }

    @Published public var gestureCooldownMs: Double {
        didSet { defaults.set(gestureCooldownMs, forKey: kGestureCooldownMs) }
    }

    @Published public var threeFingerTapAction: GestureAction {
        didSet { defaults.set(threeFingerTapAction.rawValue, forKey: kThreeFingerTapAction) }
    }

    @Published public var threeFingerDoubleTapAction: GestureAction {
        didSet { defaults.set(threeFingerDoubleTapAction.rawValue, forKey: kThreeFingerDoubleTapAction) }
    }

    @Published public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: kLaunchAtLogin) }
    }

    private init() {
        let isMigrated = defaults.bool(forKey: kConfigVersion)
        if !isMigrated {
            defaults.set(GestureAction.middleClick.rawValue, forKey: kThreeFingerTapAction)
            defaults.set(GestureAction.missionControl.rawValue, forKey: kThreeFingerDoubleTapAction)
            defaults.set(GestureAction.missionControl.rawValue, forKey: kSwipeUpAction)
            defaults.set(GestureAction.launchpad.rawValue, forKey: kSwipeDownAction)
            defaults.set(true, forKey: kSwipeUpEnabled)
            defaults.set(true, forKey: kSwipeDownEnabled)
            defaults.set(800.0, forKey: kGestureCooldownMs)
            defaults.set(false, forKey: kSmoothScrollEnabled)
            defaults.set(true, forKey: kNaturalScroll)
            defaults.set(true, forKey: kConfigVersion)
        }

        self.smoothScrollEnabled = defaults.object(forKey: kSmoothScrollEnabled) as? Bool ?? false
        self.scrollSpeed = defaults.object(forKey: kScrollSpeed) as? Double ?? 1.0
        self.momentumDecay = defaults.object(forKey: kMomentumDecay) as? Double ?? 0.92
        self.naturalScroll = defaults.object(forKey: kNaturalScroll) as? Bool ?? true
        self.horizontalFlickEnabled = defaults.object(forKey: kHorizontalFlickEnabled) as? Bool ?? true

        let leftRaw = defaults.string(forKey: kFlickLeftAction) ?? GestureAction.switchSpaceLeft.rawValue
        self.flickLeftAction = GestureAction(rawValue: leftRaw) ?? .switchSpaceLeft

        let rightRaw = defaults.string(forKey: kFlickRightAction) ?? GestureAction.switchSpaceRight.rawValue
        self.flickRightAction = GestureAction(rawValue: rightRaw) ?? .switchSpaceRight

        self.swipeUpEnabled = defaults.object(forKey: kSwipeUpEnabled) as? Bool ?? true
        let swipeUpRaw = defaults.string(forKey: kSwipeUpAction) ?? GestureAction.missionControl.rawValue
        self.swipeUpAction = GestureAction(rawValue: swipeUpRaw) ?? .missionControl

        self.swipeDownEnabled = defaults.object(forKey: kSwipeDownEnabled) as? Bool ?? true
        let swipeDownRaw = defaults.string(forKey: kSwipeDownAction) ?? GestureAction.launchpad.rawValue
        self.swipeDownAction = GestureAction(rawValue: swipeDownRaw) ?? .launchpad

        self.gestureCooldownMs = defaults.object(forKey: kGestureCooldownMs) as? Double ?? 800.0

        let tapRaw = defaults.string(forKey: kThreeFingerTapAction) ?? GestureAction.middleClick.rawValue
        self.threeFingerTapAction = GestureAction(rawValue: tapRaw) ?? .middleClick

        let dTapRaw = defaults.string(forKey: kThreeFingerDoubleTapAction) ?? GestureAction.missionControl.rawValue
        self.threeFingerDoubleTapAction = GestureAction(rawValue: dTapRaw) ?? .missionControl

        self.launchAtLogin = defaults.object(forKey: kLaunchAtLogin) as? Bool ?? true
        self.checkForUpdatesOnLaunch = defaults.object(forKey: kCheckForUpdatesOnLaunch) as? Bool ?? true
        self.hasPromptedForUpdates = defaults.object(forKey: kHasPromptedForUpdates) as? Bool ?? false
        self.isSeizureTestModeEnabled = defaults.object(forKey: kSeizureTestModeEnabled) as? Bool ?? false
    }
}
