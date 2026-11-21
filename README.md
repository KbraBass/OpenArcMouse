# OpenArcMouse 🖱️

[![CI](https://github.com/KbraBass/OpenArcMouse/actions/workflows/ci.yml/badge.svg)](https://github.com/KbraBass/OpenArcMouse/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/KbraBass/OpenArcMouse?include_prereleases&color=blue)](https://github.com/KbraBass/OpenArcMouse/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS 13+](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)](https://www.apple.com/macos/)

> **Native macOS Driver & Gesture Engine for Microsoft Arc Mouse**  
> Brings natural scrolling, multi-finger gestures, and per-device configuration to Microsoft Arc Mouse on macOS.

---

## 🌟 Why OpenArcMouse?

The **Microsoft Arc Mouse** is an iconic portable mouse with an ultra-thin design and a capacitive touch strip. However, macOS treats it like a generic two-button mouse with a stiff mechanical scroll wheel:
- Scrolling feels choppy and lacks native inertial momentum.
- Reversing scroll direction in macOS System Settings inverts **both** the mouse and your MacBook trackpad simultaneously.
- None of the rich gestures (switching Desktops / Spaces, Mission Control, App Exposé) available on Apple Magic Mouse or trackpads work on the Arc Mouse.

**OpenArcMouse** fixes all of this natively with zero external dependencies, running silently in your menu bar.

---

## ✨ Features

### 🔄 Independent Natural Scrolling (Arc Mouse Only)
- Toggle natural scrolling **strictly** for the Microsoft Arc Mouse.
- Your MacBook trackpad and any other connected mice retain their original scroll directions untouched.
- Integrates directly into the macOS display pipeline for maximum responsiveness and smooth momentum.

### 🖐️ Gesture Engine (Touch Strip + Button Chording)
Because the Microsoft Arc Mouse transmits touch interactions as discrete HID wheel and button events, OpenArcMouse introduces an intuitive button-chording gesture system:
- **Desktop / Space Switching (`Ctrl + Left/Right`):** Hold **Right Click (Button 2)** and swipe sideways across the capacitive strip to fluidly slide between virtual desktops.
- **Mission Control (`Ctrl + Up`):** Hold **Right Click** and swipe upward on the strip to open Mission Control.
- **Apps / App Exposé (`Ctrl + Down`):** Hold **Right Click** and swipe downward to view application windows.
- **Context-Menu Suppression:** When a gesture is recognized while holding Right Click, the secondary context menu is automatically suppressed when you release the button. If no swipe was performed, a standard right-click is cleanly dispatched.

### 👆 Three-Finger Click & Double-Click
- The Arc Mouse's capacitive surface emits a hardware Button 3 event when tapped or pressed with multiple fingers.
- **Single Tap/Click:** Dispatched natively as standard Middle Click (Button 3).
- **Double Tap/Click:** Triggers your chosen action (Launchpad, Mission Control, App Exposé, or browser navigation) within a configurable 380ms timing window.

### ⚡ Low Overhead & Pure Per-Device Targeting
- Intercepts events via a high-performance `CGEventTap` and `IOKit / IOHIDManager`.
- Walks the `IORegistry` hierarchy to dynamically match Microsoft Arc Mouse sender IDs (`0x045E:0x0932`, `0x082F`, `0x082A`).
- Completely ignores events from other input devices, adding zero input latency to your workflow.
- Pure macOS menu bar agent (`LSUIElement = true`) with minimal CPU and memory usage.

---

## 📥 Installation

### Option 1: Download Pre-built Release (Recommended)
1. Head over to [**Releases**](https://github.com/KbraBass/OpenArcMouse/releases).
2. Download the latest `OpenArcMouse-v0.1.0.zip`.
3. Unzip and drag `OpenArcMouse.app` to your `/Applications` folder.
4. Launch `OpenArcMouse.app`.

### Option 2: Build from Source
Ensure you have Xcode Command Line Tools installed (`xcode-select --install`):
```bash
# Clone repository
git clone https://github.com/KbraBass/OpenArcMouse.git
cd OpenArcMouse

# Build release bundle
./scripts/build-app.sh

# Install to /Applications
cp -R build/OpenArcMouse.app /Applications/
open /Applications/OpenArcMouse.app
```

---

## 🔒 Permissions & Setup

On first launch, OpenArcMouse requires two standard macOS permissions:

1. **Accessibility (`CGEventTap`):**  
   Required to intercept scroll wheel and button events from the mouse and dispatch keyboard shortcuts for desktop switching and Mission Control.  
   *Go to: System Settings → Privacy & Security → Accessibility → Enable **OpenArcMouse**.*

2. **Input Monitoring (`IOHIDManager`):**  
   Required to identify the Microsoft Arc Mouse hardware and read raw capacitive touch data.  
   *Go to: System Settings → Privacy & Security → Input Monitoring → Enable **OpenArcMouse**.*

Click the OpenArcMouse icon in your menu bar to open the menu; if any permission is missing, a prominent one-click authorization prompt will appear.

---

## 🛠️ Configuration & Preferences

Open the menu bar icon and select **Settings...** to customize your experience:
- **Scrolling Tab:** Toggle independent Natural Scrolling for the Arc Mouse.
- **Gestures Tab:** Enable/disable specific gestures, customize trigger actions (Mission Control, App Exposé, Spaces, Browser Back/Forward), and adjust the momentum cooldown filter (200ms – 2000ms).
- **General Tab:** View live device connection status and enable **Launch at Login** (`SMAppService`).
- **About Tab:** Inspect developer info, GitHub repository link, and the full MIT license.
- **Live Event Monitor:** Real-time stream of hardware deltas, gestures, and connection events to test hardware sensitivity.

---

## 💻 Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI & AppKit
- **HID & Input:** `IOKit / IOHIDManager` & `CoreGraphics / CGEventTap`
- **System Startup:** `ServiceManagement (SMAppService)`
- **Platform:** macOS 13.0+ (Ventura, Sonoma, Sequoia, and later) — Apple Silicon & Intel

---

## 👤 Developer

Developed by **Alexandre Silva ([@KbraBass](https://github.com/KbraBass))**.

- GitHub: [https://github.com/KbraBass](https://github.com/KbraBass)
- Repository: [https://github.com/KbraBass/OpenArcMouse](https://github.com/KbraBass/OpenArcMouse)

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
