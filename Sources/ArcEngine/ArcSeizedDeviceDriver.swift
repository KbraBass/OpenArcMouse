import Foundation
import IOKit
import IOKit.hid
import CoreGraphics
import AppKit
import ArcCore
import ArcHID

@_silgen_name("IOHIDCheckAccess")
private func IOHIDCheckAccess(_ type: UInt32) -> Int32

@_silgen_name("IOHIDRequestAccess")
private func IOHIDRequestAccess(_ type: UInt32) -> Bool

public final class ArcSeizedDeviceDriver: ObservableObject {
    public static let shared = ArcSeizedDeviceDriver()

    @Published public private(set) var isSeized: Bool = false
    @Published public private(set) var deviceName: String = ""
    @Published public private(set) var hasInputMonitoringPermission: Bool = false

    private var hidManager: IOHIDManager?
    private var seizedDevice: IOHIDDevice?
    private var permissionTimer: Timer?

    private init() {
        checkPermission()
        setupManager()
        startPermissionTimer()
    }

    public func checkPermission() {
        let granted = (IOHIDCheckAccess(1) == 0)
        if granted != self.hasInputMonitoringPermission {
            self.hasInputMonitoringPermission = granted
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            if granted && !isSeized {
                scanExistingDevices()
            }
        }
    }

    public func requestInputMonitoringPermission() {
        _ = IOHIDRequestAccess(1)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startPermissionTimer() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }

    public func start() {
        if hidManager == nil {
            setupManager()
        } else {
            scanExistingDevices()
        }
    }

    private func setupManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager

        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: ArcDeviceDefinition.microsoftVendorId
        ]
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()

        let matchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let driver = Unmanaged<ArcSeizedDeviceDriver>.fromOpaque(context).takeUnretainedValue()
            driver.handleDeviceMatched(device)
        }

        let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let driver = Unmanaged<ArcSeizedDeviceDriver>.fromOpaque(context).takeUnretainedValue()
            driver.handleDeviceRemoved(device)
        }

        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        _ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        scanExistingDevices()
    }

    private func scanExistingDevices() {
        guard let manager = hidManager else { return }
        if let existing = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> {
            for dev in existing {
                handleDeviceMatched(dev)
            }
        }
    }

    private func handleDeviceMatched(_ device: IOHIDDevice) {
        let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        let vendorId = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let productId = (IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? NSNumber)?.intValue ?? 0

        guard ArcDeviceDefinition.isArcMouse(vendorId: vendorId, productId: productId, productName: product) else {
            return
        }

        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let openResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        if openResult == kIOReturnSuccess {
            self.seizedDevice = device
            self.isSeized = true
            self.deviceName = product.isEmpty ? "Microsoft Arc Mouse" : product

            ArcEventMonitor.shared.record(category: .device, detail: "Connected: \(self.deviceName)")

            let context = Unmanaged.passUnretained(self).toOpaque()
            IOHIDDeviceRegisterInputValueCallback(device, inputValueCallback, context)

            // Trigger sender IDs refresh in DeviceWatcher
            DeviceWatcher.shared.refreshArcMouseSenderIDs()

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else {
            ArcEventMonitor.shared.record(category: .device, detail: "Device Open Failed (IOReturn: \(openResult))")
        }
    }

    private func handleDeviceRemoved(_ device: IOHIDDevice) {
        if device == seizedDevice {
            ArcEventMonitor.shared.record(category: .device, detail: "Device Disconnected")
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            self.seizedDevice = nil
            self.isSeized = false
            self.deviceName = ""
            GestureEngine.shared.isButton2Down = false
            GestureEngine.shared.isButton3Down = false

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    fileprivate func processValue(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let page = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        let intVal = IOHIDValueGetIntegerValue(value)

        switch page {
        case 0x0001: // Generic Desktop
            switch usage {
            case 0x0030: // X displacement
                if intVal != 0 { ArcEventMonitor.shared.record(category: .device, detail: "Raw Delta X: \(intVal)") }
            case 0x0031: // Y displacement
                if intVal != 0 { ArcEventMonitor.shared.record(category: .device, detail: "Raw Delta Y: \(intVal)") }
            case 0x0038: // Wheel (Vertical scroll on capacitive strip)
                if intVal != 0 {
                    ArcEventMonitor.shared.record(category: .verticalScroll, detail: "Hardware Wheel: \(intVal)")
                }
            default:
                break
            }

        case 0x000C: // Consumer / Controls
            if usage == 0x0238 { // AC Pan (Horizontal swipe on capacitive strip)
                if intVal != 0 {
                    ArcEventMonitor.shared.record(category: .horizontalPan, detail: "Hardware Pan: \(intVal)")
                }
            }

        case 0x0009: // Buttons
            let isDown = (intVal != 0)
            let state = isDown ? "DOWN" : "UP"
            ArcEventMonitor.shared.record(category: .button, detail: "Hardware Button \(usage): \(state)")

            // Track Button 2 (Right click / secondary) state for Button-2 + side-scroll gesture
            if usage == 2 {
                GestureEngine.shared.isButton2Down = isDown
            }

            // Button 3 on Microsoft Arc Mouse is the 3-finger physical click
            if usage == 3 {
                GestureEngine.shared.isButton3Down = isDown
                if isDown && !ArcConfig.shared.isSeizureTestModeEnabled {
                    GestureEngine.shared.handleThreeFingerClick()
                }
            }

        default:
            break
        }
    }
}

private func inputValueCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    value: IOHIDValue
) {
    guard let context = context else { return }
    let driver = Unmanaged<ArcSeizedDeviceDriver>.fromOpaque(context).takeUnretainedValue()
    driver.processValue(value)
}
