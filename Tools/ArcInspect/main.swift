import Foundation
import IOKit
import IOKit.hid
import ArcCore

setbuf(stdout, nil)
print("""
================================================================
           Arc Mouse Hardware Seizure Elevation Test           
================================================================
Running as UID: \(getuid()) (\(getuid() == 0 ? "ROOT / ELEVATED" : "STANDARD USER"))
Testing if kIOHIDOptionsTypeSeizeDevice locks the device from macOS...
================================================================
""")

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matchingDict: [String: Any] = [
    kIOHIDVendorIDKey: ArcDeviceDefinition.microsoftVendorId
]
IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
let mgrStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
print("IOHIDManagerOpen status: \(mgrStatus)")

guard let existing = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, let device = existing.first else {
    print("[!] Microsoft Arc Mouse not found. Please curve/turn on mouse.")
    exit(1)
}

let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Microsoft Arc Mouse"
print("[+] Target Device: \(product)")

IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
let seizeResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
print("IOHIDDeviceOpen(kIOHIDOptionsTypeSeizeDevice) result: \(seizeResult)")

if seizeResult == kIOReturnSuccess {
    print("""
    [+] Device SEIZED!
    NOW MOVE AND SCROLL YOUR MOUSE:
      - If cursor DOES NOT move and scrolling DOES NOT work in apps -> ROOT SEIZURE SUCCEEDED!
      - If cursor STILL moves -> macOS DriverKit bypasses seizure even for root.
    """)
} else {
    print("[-] Seizure failed with error: \(seizeResult)")
}

let valueCallback: IOHIDValueCallback = { context, result, sender, value in
    let element = IOHIDValueGetElement(value)
    let page = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    let intVal = IOHIDValueGetIntegerValue(value)

    if intVal != 0 {
        print("  -> Raw Event: Page 0x\(String(format: "%04X", page)) Usage 0x\(String(format: "%04X", usage)) Val: \(intVal)")
    }
}
IOHIDDeviceRegisterInputValueCallback(device, valueCallback, nil)

print("Listening for 15 seconds...")
RunLoop.current.run(until: Date().addingTimeInterval(15.0))
print("Done. Releasing device.")
IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
