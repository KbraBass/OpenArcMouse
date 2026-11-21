import Foundation

public struct ArcDeviceDefinition {
    public static let microsoftVendorId: Int = 0x045E

    public static let knownProductIds: [Int: String] = [
        0x0932: "Microsoft Arc Mouse (Bluetooth LE)",
        0x082F: "Surface Arc Mouse (Bluetooth LE)",
        0x082A: "Microsoft Arc Mouse",
        0x07B1: "Arc Touch Mouse Surface Edition",
        0x07FA: "Arc Touch Bluetooth Mouse"
    ]

    public static func isArcMouse(vendorId: Int, productId: Int, productName: String? = nil) -> Bool {
        if vendorId == microsoftVendorId {
            if knownProductIds.keys.contains(productId) {
                return true
            }
            if let name = productName?.lowercased(), name.contains("arc") {
                return true
            }
        }
        if let name = productName?.lowercased(), name.contains("arc mouse") {
            return true
        }
        return false
    }
}
