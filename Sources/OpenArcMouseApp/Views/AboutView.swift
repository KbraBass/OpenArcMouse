import SwiftUI
import AppKit

public struct AboutView: View {
    @State private var showingLicenseModal = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private let mitLicenseText = """
    MIT License

    Copyright (c) 2026 Alexandre Silva

    Permission is hereby granted, free of charge, to any person obtaining a copy \
    of this software and associated documentation files (the "Software"), to deal \
    in the Software without restriction, including without limitation the rights \
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
    copies of the Software, and to permit persons to whom the Software is \
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all \
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
    SOFTWARE.
    """

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 6)

            // App Icon
            if let icon = NSImage(named: "AppIcon") ?? NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
            } else {
                Image(systemName: "computermouse.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundColor(.accentColor)
            }

            // App Name & Version
            VStack(spacing: 4) {
                Text("OpenArcMouse")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Native macOS driver and gesture engine for Microsoft Arc Mouse.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 28)

            Divider()
                .padding(.horizontal, 24)

            // Details Card
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text("Developer:")
                        .fontWeight(.semibold)
                        .frame(width: 90, alignment: .leading)
                    Link("Alexandre Silva (KbraBass)", destination: URL(string: "https://github.com/KbraBass")!)
                        .foregroundColor(.accentColor)
                }

                HStack(alignment: .top) {
                    Text("GitHub:")
                        .fontWeight(.semibold)
                        .frame(width: 90, alignment: .leading)
                    Link("github.com/KbraBass/OpenArcMouse", destination: URL(string: "https://github.com/KbraBass/OpenArcMouse")!)
                        .foregroundColor(.accentColor)
                }

                HStack(alignment: .top) {
                    Text("License:")
                        .fontWeight(.semibold)
                        .frame(width: 90, alignment: .leading)
                    HStack(spacing: 8) {
                        Text("MIT License")
                        Button("View Text") {
                            showingLicenseModal.toggle()
                        }
                        .buttonStyle(.link)
                        .font(.callout)
                    }
                }
            }
            .font(.callout)
            .padding(.horizontal, 32)

            Spacer()

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: "https://github.com/KbraBass/OpenArcMouse") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub Repository", systemImage: "link")
                }

                Button(action: {
                    if let url = URL(string: "https://github.com/KbraBass/OpenArcMouse/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Releases", systemImage: "arrow.down.circle")
                }
            }

            Text("Copyright © 2026 Alexandre Silva. Released under the MIT License.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .frame(minWidth: 420, maxWidth: 520, minHeight: 440)
        .padding(16)
        .sheet(isPresented: $showingLicenseModal) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MIT License")
                        .font(.headline)
                    Spacer()
                    Button("Done") {
                        showingLicenseModal = false
                    }
                    .keyboardShortcut(.defaultAction)
                }

                ScrollView {
                    Text(mitLicenseText)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            }
            .padding(16)
            .frame(width: 480, height: 320)
        }
    }
}
