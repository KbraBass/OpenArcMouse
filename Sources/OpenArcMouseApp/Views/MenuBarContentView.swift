import SwiftUI
import ArcCore
import ArcEngine

public struct MenuBarContentView: View {
    @ObservedObject var config = ArcConfig.shared
    @ObservedObject var driver = ArcSeizedDeviceDriver.shared
    @ObservedObject var tapManager = EventTapManager.shared

    var openSettings: () -> Void
    var openMonitor: () -> Void
    var openAbout: () -> Void

    public init(openSettings: @escaping () -> Void, openMonitor: @escaping () -> Void, openAbout: @escaping () -> Void) {
        self.openSettings = openSettings
        self.openMonitor = openMonitor
        self.openAbout = openAbout
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Status Header
            HStack {
                Circle()
                    .fill(driver.isSeized ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(driver.isSeized ? (driver.deviceName.isEmpty ? "Microsoft Arc Mouse" : driver.deviceName) : "Arc Mouse Disconnected")
                    .font(.subheadline)
                    .bold()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)

            Divider()

            // Natural Scrolling (Arc Mouse Only)
            Toggle("Natural Scrolling (Arc Only)", isOn: $config.naturalScroll)
                .padding(.horizontal, 10)
                .help("Inverts scroll direction strictly on the Arc Mouse. Does not affect trackpads or other mice.")

            Divider()

            // Gestures
            Text("Gestures (Hold Button 2 + Swipe)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)

            Toggle("Side Swipe → Desktops", isOn: $config.horizontalFlickEnabled)
                .padding(.horizontal, 10)

            Toggle("Swipe Up → Mission Control", isOn: $config.swipeUpEnabled)
                .padding(.horizontal, 10)

            Toggle("Swipe Down → Apps", isOn: $config.swipeDownEnabled)
                .padding(.horizontal, 10)

            Divider()

            HStack {
                Text("3-Finger Double-Click:")
                    .font(.subheadline)
                Spacer()
                Text(config.threeFingerDoubleTapAction.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)

            Divider()

            Button(action: openMonitor) {
                Label("Live Event Monitor...", systemImage: "waveform.path.ecg")
            }
            .padding(.horizontal, 10)

            if !tapManager.hasAccessibilityPermission {
                Button(action: {
                    tapManager.requestPermission()
                }) {
                    Label("Grant Accessibility...", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
            }

            if !driver.hasInputMonitoringPermission {
                Button(action: {
                    driver.requestInputMonitoringPermission()
                }) {
                    Label("Grant Input Monitoring...", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
            }

            Button(action: openSettings) {
                Label("Settings...", systemImage: "slider.horizontal.3")
            }
            .padding(.horizontal, 10)

            Button(action: openAbout) {
                Label("About OpenArcMouse...", systemImage: "info.circle")
            }
            .padding(.horizontal, 10)

            Divider()

            Button("Quit OpenArcMouse") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }
        .frame(width: 270)
        .padding(.vertical, 6)
    }
}
