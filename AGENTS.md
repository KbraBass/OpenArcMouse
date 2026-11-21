# AGENTS.md — AI Developer Guide for OpenArcMouse

This document serves as the canonical orientation and architecture reference for AI coding agents (and human contributors) interacting with, refactoring, or extending the **OpenArcMouse** codebase.

---

## 1. Project Purpose & High-Level Architecture

OpenArcMouse is a native macOS background driver and gesture engine specifically crafted for the **Microsoft Arc Mouse**. macOS lacks built-in gesture support for non-Apple mice and links global natural scrolling direction across all pointing devices. OpenArcMouse provides:
1. **Per-device natural scrolling inversion** strictly for the Arc Mouse without affecting MacBook trackpads or other pointing devices.
2. **Gesture recognition** using button chording (Holding Button 2 + swiping capacitive strip) to trigger macOS system actions (Spaces/Desktops switching, Mission Control, App Exposé).
3. **Three-finger tap and double-click handling** via capacitive surface button events (Button 3).
4. **Live Event Monitor** and Menu Bar configuration UI built with SwiftUI.

---

## 2. Directory & Module Structure

```
.
├── Package.swift               # SPM package definition (targets, dependencies, tools)
├── Resources/
│   ├── AppIcon.icns            # macOS app bundle icon
│   └── AppIcon.png             # Raw raster icon
├── scripts/
│   └── build-app.sh            # Release build & app bundle packaging script
├── Sources/
│   ├── ArcCore/                # Foundation data structures, configuration & models
│   │   ├── ArcConfig.swift     # UserDefaults-persisted reactive configuration
│   │   ├── ArcDevice.swift     # Device VID/PID definitions & matching predicates
│   │   └── GestureAction.swift # Enumeration of configurable gesture actions
│   ├── ArcHID/                 # Low-level hardware monitoring & identification
│   │   └── DeviceWatcher.swift # IOHIDManager & IORegistry hierarchy matching
│   ├── ArcEngine/              # Core input processing, gestures & display pipeline
│   │   ├── EventTapManager.swift        # CGEventTap session hook (.headInsertEventTap)
│   │   ├── GestureEngine.swift          # Velocity, accumulator, & cooldown state machine
│   │   ├── GestureDispatcher.swift      # Hotkey & synthesized event dispatch
│   │   ├── SmoothScrollEngine.swift     # Synthetic event tagging & constants
│   │   ├── ArcSeizedDeviceDriver.swift  # Direct raw IOHIDDevice input monitoring
│   │   └── ArcEventMonitor.swift        # In-memory circular buffer for UI diagnostics
│   └── OpenArcMouseApp/        # SwiftUI Application & Menu Bar Extra
│       ├── AppMain.swift                # App entry point, AppDelegate & window lifecycles
│       ├── AutoLaunchManager.swift      # SMAppService login item registration
│       └── Views/
│           ├── MenuBarContentView.swift # Dropdown menu view
│           ├── SettingsWindowView.swift # Multi-tab preferences window
│           ├── AboutView.swift          # Developer info, repo link & MIT license modal
│           └── EventMonitorWindowView.swift # Real-time event visualizer
├── Tools/
│   ├── ArcInspect/             # Standalone CLI tool to probe raw IOHID elements
│   └── ArcMonitor/             # Standalone CLI tool to stream scroll & button events
├── .github/
│   └── workflows/
│       ├── ci.yml              # CI workflow (build, package, codesign validation)
│       └── release.yml         # Tag-driven release workflow (builds, zips, publishes)
└── LICENSE                     # MIT License
```

---

## 3. Hardware & HID Protocol Details

### Device Identifiers
- **Vendor ID:** `0x045E` (Microsoft Corporation)
- **Product IDs:**
  - `0x0932`: Microsoft Arc Mouse (Surface Arc / modern Bluetooth model)
  - `0x082F`: Microsoft Arc Touch Bluetooth Mouse
  - `0x082A`: Surface Arc Mouse variant

### Hardware Quirks & Limitations
- The Arc Mouse does **not** expose a multi-touch digitizer stream like Apple Magic Mouse. It operates as a standard HID mouse with a capacitive strip.
- **Vertical Scroll:** Emitted as HID Usage Page `0x0001` (Generic Desktop), Usage `0x0038` (Wheel).
- **Horizontal Pan:** Emitted as HID Usage Page `0x000C` (Consumer Controls), Usage `0x0238` (AC Pan).
- **Physical Buttons:**
  - Usage `0x0001`: Primary Click (Left)
  - Usage `0x0002`: Secondary Click (Right)
  - Usage `0x0003`: Capacitive surface multi-finger press (Middle Click)

---

## 4. Event Processing Pipeline

```
[Microsoft Arc Mouse Hardware]
              │
       (IOHIDEvent Stream)
              ▼
   ┌──────────────────────┐
   │ DeviceWatcher.swift  │  Walks IORegistry to cache SenderIDs (filters out
   └──────────────────────┘  trackpads, virtual mice, remote sessions)
              │
              ▼
   ┌──────────────────────┐
   │ EventTapManager.swift│  CGEventTap (.headInsertEventTap, .cgSessionEventTap)
   └──────────────────────┘
              │
      Is Right Button Held?
      ├── YES ──► GestureEngine.swift ──► Swipe dx >= Threshold? ──► Switch Desktops
      │                               ──► Swipe dy >= Threshold? ──► Mission Control
      │                               (Suppresses scroll and right-click menu)
      │
      └── NO  ──► Natural Scroll?
                  ├── Invert scrollWheel deltaAxis1/2 directly in CGEvent
                  └── Pass modified event directly to native macOS display pipeline
```

### Synthetic Event Tagging
Any synthesized event injected back into the event stream is tagged with `SmoothScrollEngine.magicEventTag` in `eventSourceUserData`. The event tap immediately checks `SmoothScrollEngine.isSyntheticEvent(event)` and ignores it to avoid infinite recursion loops.

---

## 5. Critical Invariants & Rules for AI Agents

1. **NO Disk Logging in Production:**
   - Never write logs or diagnostic data to disk (e.g. `/tmp/`).
   - Diagnostic streaming for the UI must exclusively go through `ArcEventMonitor.shared.record(...)` (in-memory circular buffer capped at 150 events).
   - CLI diagnostic tools under `Tools/` may use `print()`.

2. **Thread Safety & UI Updates:**
   - All `@Published` properties on shared singletons (`ArcConfig`, `ArcSeizedDeviceDriver`, `EventTapManager`, `ArcEventMonitor`) must be mutated on the main thread via `DispatchQueue.main.async`.

3. **Designated Requirement Code Signing:**
   - In `scripts/build-app.sh`, code signing uses:
     ```bash
     codesign --force --deep --sign - -r='designated => identifier "com.openarc.mouse"' "$APP_DIR"
     ```
   - This exact designated requirement ensures macOS TCC (Accessibility and Input Monitoring) permissions persist across app rebuilds. Never alter the bundle identifier `com.openarc.mouse` without updating all build and packaging scripts.

4. **Pure Per-Device Targeting:**
   - Never intercept or modify events without verifying `DeviceWatcher.shared.isArcMouseEvent(event)`. Events from Apple trackpads or other mice must pass through untouched.

5. **Release Versioning:**
   - Versioning follows SemVer (`MAJOR.MINOR.PATCH`).
   - Starting release: `0.1.0`.
   - The version can be passed dynamically to `scripts/build-app.sh` via the `VERSION` environment variable:
     ```bash
     VERSION="0.1.0" ./scripts/build-app.sh
     ```

---

## 6. Build, Test, & Release Commands

### Build from Terminal
```bash
# Debug build
swift build

# Release build
swift build -c release

# Package signed .app bundle
./scripts/build-app.sh
```

### Run App
```bash
open build/OpenArcMouse.app
```

### Run Diagnostic CLI Tools
```bash
# Inspect raw HID stream
swift run arc-inspect

# Monitor live scroll and button events
swift run arc-monitor
```

### CI / CD Workflows
- `.github/workflows/ci.yml`: Runs on PRs and pushes to `main`. Verifies `swift build -c release` and packages the bundle on `macos-14`.
- `.github/workflows/release.yml`: Runs on Git tags matching `v*` (e.g., `git tag v0.1.0 && git push origin v0.1.0`) or manual `workflow_dispatch`. Generates `OpenArcMouse-v<version>.zip`, computes SHA256, and publishes a GitHub Release.
