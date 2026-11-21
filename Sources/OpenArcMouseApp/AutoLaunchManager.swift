import Foundation
import ServiceManagement
import ArcCore

public struct AutoLaunchManager {
    public static func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status != .enabled {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
            } catch {
                // Silently ignore or allow retry on next toggle
            }
        }
    }
}
