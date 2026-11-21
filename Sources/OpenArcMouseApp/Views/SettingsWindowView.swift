import SwiftUI
import ArcCore
import ArcEngine
import ArcHID

public struct SettingsWindowView: View {
    @ObservedObject var config = ArcConfig.shared
    @ObservedObject var driver = ArcSeizedDeviceDriver.shared

    public init() {}

    public var body: some View {
        TabView {
            scrollingTab
                .tabItem {
                    Label("Scrolling", systemImage: "arrow.up.and.down")
                }

            gesturesTab
                .tabItem {
                    Label("Gestures", systemImage: "hand.tap")
                }

            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 560, minHeight: 500)
        .padding(16)
    }

    private var scrollingTab: some View {
        Form {
            Section {
                Toggle("Natural Scrolling Direction (Arc Mouse Only)", isOn: $config.naturalScroll)
                Text("Inverts scroll direction strictly for the Arc Mouse. Does NOT affect your MacBook trackpad or other connected mice. Uses macOS native display pipeline for maximum smoothness.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Arc Mouse Scrolling")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    private var gesturesTab: some View {
        Form {
            Section {
                Text("Hold Button 2 (Secondary / Right-Click) down with one finger, then swipe along the capacitive touch strip with another finger (e.g., hold Button 2 with your middle finger and swipe the strip with your index finger). Performing both actions with a single finger does not glide smoothly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle("Side Swipe (Switch Desktops / Spaces)", isOn: $config.horizontalFlickEnabled)

                if config.horizontalFlickEnabled {
                    Picker("Swipe Left:", selection: $config.flickLeftAction) {
                        ForEach(GestureAction.allCases) { action in
                            Label(action.displayName, systemImage: action.iconName).tag(action)
                        }
                    }

                    Picker("Swipe Right:", selection: $config.flickRightAction) {
                        ForEach(GestureAction.allCases) { action in
                            Label(action.displayName, systemImage: action.iconName).tag(action)
                        }
                    }
                }

                Toggle("Swipe Up (Mission Control)", isOn: $config.swipeUpEnabled)

                if config.swipeUpEnabled {
                    Picker("Swipe Up Action:", selection: $config.swipeUpAction) {
                        ForEach(GestureAction.allCases) { action in
                            Label(action.displayName, systemImage: action.iconName).tag(action)
                        }
                    }
                }

                Toggle("Swipe Down (Apps / App Drawer)", isOn: $config.swipeDownEnabled)

                if config.swipeDownEnabled {
                    Picker("Swipe Down Action:", selection: $config.swipeDownAction) {
                        ForEach(GestureAction.allCases) { action in
                            Label(action.displayName, systemImage: action.iconName).tag(action)
                        }
                    }
                }
            } header: {
                Text("Button-2 + Touch Strip Gestures")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cooldown Duration:")
                        Spacer()
                        TextField("ms", value: $config.gestureCooldownMs, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 75)
                            .multilineTextAlignment(.trailing)
                        Text("ms")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $config.gestureCooldownMs, in: 200...2000, step: 50) {
                        Text("Cooldown")
                    } minimumValueLabel: {
                        Text("200ms").font(.caption).foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("2000ms").font(.caption).foregroundColor(.secondary)
                    }

                    Text("Filters out residual momentum scroll ticks from the capacitive touch strip so actions like Mission Control don't repeatedly open and close.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Gesture Momentum & Cooldown Filter")
                    .font(.headline)
            }

            Section {
                Picker("3-Finger Double-Click:", selection: $config.threeFingerDoubleTapAction) {
                    ForEach(GestureAction.allCases) { action in
                        Label(action.displayName, systemImage: action.iconName).tag(action)
                    }
                }

                Text("Single click acts as standard native Middle-Click (Button 3). Double-clicking within 380ms triggers the selected action.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Three-Finger Gestures (Surface Tap / Click)")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    private var generalTab: some View {
        Form {
            Section {
                HStack {
                    Circle()
                        .fill(driver.isSeized ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(driver.isSeized ? (driver.deviceName.isEmpty ? "Microsoft Arc Mouse" : driver.deviceName) : "Disconnected")
                        .font(.headline)
                }

                HStack {
                    Text("Driver Engine:")
                    Spacer()
                    if driver.isSeized {
                        Label("Arc Mouse Connected & Monitored", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Waiting for Arc Mouse connection...", systemImage: "hourglass")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Device Status")
                    .font(.headline)
            }

            Section {
                Toggle("Launch OpenArcMouse at Login", isOn: $config.launchAtLogin)
            } header: {
                Text("System Startup")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }
}
