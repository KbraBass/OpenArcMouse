import SwiftUI
import ArcCore
import ArcEngine

public struct EventMonitorWindowView: View {
    @ObservedObject var monitor = ArcEventMonitor.shared
    @ObservedObject var driver = ArcSeizedDeviceDriver.shared
    @ObservedObject var config = ArcConfig.shared

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Header Stats Card
            HStack(spacing: 16) {
                // Connection
                HStack(spacing: 8) {
                    Circle()
                        .fill(driver.isSeized ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driver.isSeized ? "Hardware Driver" : "Waiting for Mouse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(driver.isSeized ? driver.deviceName : "Disconnected")
                            .font(.subheadline)
                            .bold()
                    }
                }

                Divider().frame(height: 32)

                // Vertical delta
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Vertical")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%+.1f", monitor.lastVerticalDelta))
                        .font(.system(.subheadline, design: .monospaced))
                        .bold()
                        .foregroundColor(.blue)
                }

                Divider().frame(height: 32)

                // Horizontal delta
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Horizontal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%+.1f", monitor.lastHorizontalDelta))
                        .font(.system(.subheadline, design: .monospaced))
                        .bold()
                        .foregroundColor(.purple)
                }

                Divider().frame(height: 32)

                // Last Action
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Gesture")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(monitor.lastAction)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.green)
                }

                Spacer()

                Button("Clear") {
                    monitor.clear()
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Test Mode Control Bar
            HStack {
                Toggle("Mute Event Synthesis (Seizure Lock Test)", isOn: $config.isSeizureTestModeEnabled)
                    .font(.subheadline)
                    .foregroundColor(config.isSeizureTestModeEnabled ? .red : .primary)
                    .help("When checked, OpenArcMouse logs all events but emits ZERO synthetic movement or clicks. If the mouse still works in macOS, the stock driver is bypassing seizure.")

                Spacer()

                if config.isSeizureTestModeEnabled {
                    Text("SYNTHESIS MUTED")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 4)

            // Events List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if monitor.events.isEmpty {
                            Text("Waiting for mouse input... Swipe or click your Arc Mouse.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(40)
                        } else {
                            ForEach(monitor.events) { ev in
                                HStack(spacing: 10) {
                                    Text(Self.timeFormatter.string(from: ev.timestamp))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)

                                    Label(ev.category.rawValue, systemImage: ev.category.icon)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(ev.category.color)
                                        .frame(width: 80, alignment: .leading)

                                    Text(ev.detail)
                                        .font(.system(size: 12, design: .monospaced))

                                    Spacer()
                                }
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.4))
                                .cornerRadius(4)
                                .id(ev.id)
                            }
                        }
                    }
                    .padding(8)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .onChange(of: monitor.events.count) { _ in
                    if let last = monitor.events.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 580, minHeight: 400)
    }
}
