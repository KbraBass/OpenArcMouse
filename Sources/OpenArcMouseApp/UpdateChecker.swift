import Foundation
import AppKit
import ArcCore

public final class UpdateChecker: ObservableObject {
    public static let shared = UpdateChecker()

    @Published public var isChecking: Bool = false

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlUrl: String
        let name: String?
        let body: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
            case name
            case body
        }
    }

    private init() {}

    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.3"
    }

    /// Checks for updates against the GitHub Releases API.
    /// - Parameter isUserInitiated: If true, informs the user when they are up-to-date or if an error occurs.
    public func checkForUpdates(isUserInitiated: Bool = false) {
        guard !isChecking else { return }

        DispatchQueue.main.async {
            self.isChecking = true
        }

        guard let url = URL(string: "https://api.github.com/repos/KbraBass/OpenArcMouse/releases/latest") else {
            DispatchQueue.main.async { self.isChecking = false }
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12.0)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("OpenArcMouse-App", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isChecking = false

                if let error = error {
                    if isUserInitiated {
                        self.showErrorAlert(message: error.localizedDescription)
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    if isUserInitiated {
                        self.showErrorAlert(message: "Invalid server response.")
                    }
                    return
                }

                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    if isUserInitiated {
                        self.showErrorAlert(message: "Server returned status code \(httpResponse.statusCode).")
                    }
                    return
                }

                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    let latestTag = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                    let current = self.currentVersion.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

                    if self.isVersion(latestTag, greaterThan: current) {
                        self.showUpdateAvailableAlert(release: release, currentVersion: current, latestVersion: latestTag)
                    } else if isUserInitiated {
                        self.showUpToDateAlert(currentVersion: current)
                    }
                } catch {
                    if isUserInitiated {
                        self.showErrorAlert(message: "Failed to parse release information: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }

    /// Compares two SemVer strings (e.g. "0.1.3" vs "0.1.2").
    public func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(parts1.count, parts2.count)

        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }

    private func showUpdateAvailableAlert(release: GitHubRelease, currentVersion: String, latestVersion: String) {
        let alert = NSAlert()
        alert.messageText = "OpenArcMouse Update Available"
        alert.informativeText = "A new version of OpenArcMouse is available!\n\n• Installed: v\(currentVersion)\n• Latest: v\(latestVersion)\n\nWould you like to open GitHub to download the update?"
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .informational

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func showUpToDateAlert(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date!"
        alert.informativeText = "OpenArcMouse v\(currentVersion) is currently the newest available release."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not check for updates.\n\n\(message)"
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
