import Foundation
import IOKit
import IOKit.hid
import CoreGraphics
import ArcCore

@_silgen_name("CGEventCopyIOHIDEvent")
private func CGEventCopyIOHIDEvent(_ event: CGEvent) -> CFTypeRef?

@_silgen_name("IOHIDEventGetSenderID")
private func IOHIDEventGetSenderID(_ event: CFTypeRef) -> UInt64

public final class DeviceWatcher: ObservableObject {
    public static let shared = DeviceWatcher()

    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var deviceName: String = ""
    public private(set) var arcMouseSenderIDs = Set<UInt64>()
    private var nonArcSenderIDs = Set<UInt64>()

    private var hidManager: IOHIDManager?
    public var onConnectionChanged: ((Bool) -> Void)?

    private init() {
        setupManager()
        refreshArcMouseSenderIDs()
    }

    private func setupManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager

        let matchingDicts: [[String: Any]] = [
            [kIOHIDVendorIDKey: ArcDeviceDefinition.microsoftVendorId],
            [kIOHIDDeviceUsagePageKey: 0x01, kIOHIDDeviceUsageKey: 0x02] // Generic Desktop Mouse
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingDicts as CFArray)

        let context = Unmanaged.passUnretained(self).toOpaque()

        let matchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let watcher = Unmanaged<DeviceWatcher>.fromOpaque(context).takeUnretainedValue()
            watcher.handleDeviceMatched(device)
        }

        let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let watcher = Unmanaged<DeviceWatcher>.fromOpaque(context).takeUnretainedValue()
            watcher.handleDeviceRemoved(device)
        }

        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        _ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    /// Queries IORegistry directly for all AppleUserHIDEventService instances associated with Microsoft Arc Mouse
    public func refreshArcMouseSenderIDs() {
        var ids = Set<UInt64>()

        if let matching = IOServiceMatching("AppleUserHIDEventService") as NSMutableDictionary? {
            var iterator: io_iterator_t = 0
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess {
                var entry = IOIteratorNext(iterator)
                while entry != 0 {
                    let product = IORegistryEntryCreateCFProperty(entry, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? ""
                    let vid = IORegistryEntryCreateCFProperty(entry, "VendorID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int ?? 0

                    if vid == ArcDeviceDefinition.microsoftVendorId || product.contains("Arc") {
                        var id: UInt64 = 0
                        if IORegistryEntryGetRegistryEntryID(entry, &id) == kIOReturnSuccess {
                            ids.insert(id)
                        }
                    }
                    IOObjectRelease(entry)
                    entry = IOIteratorNext(iterator)
                }
                IOObjectRelease(iterator)
            }
        }

        self.arcMouseSenderIDs = ids
        if !ids.isEmpty {
            self.isConnected = true
            self.deviceName = "Microsoft Arc Mouse"
            self.onConnectionChanged?(true)
        }
    }

    private func handleDeviceMatched(_ device: IOHIDDevice) {
        let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        let vendorId = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let productId = (IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? NSNumber)?.intValue ?? 0

        if ArcDeviceDefinition.isArcMouse(vendorId: vendorId, productId: productId, productName: product) {
            refreshArcMouseSenderIDs()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private func handleDeviceRemoved(_ device: IOHIDDevice) {
        let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        let vendorId = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let productId = (IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? NSNumber)?.intValue ?? 0

        if ArcDeviceDefinition.isArcMouse(vendorId: vendorId, productId: productId, productName: product) {
            arcMouseSenderIDs.removeAll()
            self.isConnected = false
            self.deviceName = ""
            self.onConnectionChanged?(false)

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    /// Determines strictly whether a given CGEvent originated from the Microsoft Arc Mouse
    public func isArcMouseEvent(_ event: CGEvent) -> Bool {
        // Event MUST have an underlying IOHIDEvent (filters out remote sessions, VNC, and virtual mice)
        guard let hidEvent = CGEventCopyIOHIDEvent(event) else {
            return false
        }

        let senderID = IOHIDEventGetSenderID(hidEvent)
        guard senderID != 0 else { return false }

        // Native trackpads always emit continuous scroll events
        if event.type == .scrollWheel {
            let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
            if isContinuous {
                return false // Apple trackpad
            }
        }

        return isArcMouseSenderID(senderID)
    }

    /// Checks if a senderID belongs to the Microsoft Arc Mouse by walking up its IORegistry hierarchy
    public func isArcMouseSenderID(_ senderID: UInt64) -> Bool {
        guard senderID != 0 else { return false }

        if arcMouseSenderIDs.contains(senderID) {
            return true
        }

        if nonArcSenderIDs.contains(senderID) {
            return false
        }

        let matching = IORegistryEntryIDMatching(senderID) as NSMutableDictionary
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard entry != 0 else {
            nonArcSenderIDs.insert(senderID)
            return false
        }

        var current = entry
        while current != 0 {
            if let vid = IORegistryEntryCreateCFProperty(current, "VendorID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                if vid == ArcDeviceDefinition.microsoftVendorId {
                    arcMouseSenderIDs.insert(senderID)
                    self.isConnected = true
                    self.deviceName = "Microsoft Arc Mouse"
                    IOObjectRelease(current)
                    return true
                }
            }
            if let product = IORegistryEntryCreateCFProperty(current, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                if product.contains("Arc") {
                    arcMouseSenderIDs.insert(senderID)
                    self.isConnected = true
                    self.deviceName = product
                    IOObjectRelease(current)
                    return true
                }
            }
            var parent: io_registry_entry_t = 0
            if IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent) == kIOReturnSuccess {
                IOObjectRelease(current)
                current = parent
            } else {
                IOObjectRelease(current)
                break
            }
        }

        nonArcSenderIDs.insert(senderID)
        return false
    }
}
