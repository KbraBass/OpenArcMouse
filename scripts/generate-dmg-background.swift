import AppKit
import Foundation

// Exact window size: 660 x 400
let width: CGFloat = 660
let height: CGFloat = 400

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Failed to create bitmap rep")
}

rep.size = NSSize(width: width, height: height)

guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("Failed to create graphics context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let cgContext = context.cgContext

// 1. Soft, washed-out modern dark gradient background
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradientColors = [
    NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.18, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.13, alpha: 1.0).cgColor
] as CFArray
let gradientLocations: [CGFloat] = [0.0, 1.0]
if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: gradientLocations) {
    cgContext.drawLinearGradient(
        gradient,
        start: CGPoint(x: width / 2, y: height),
        end: CGPoint(x: width / 2, y: 0),
        options: []
    )
}

// 2. Washed-out subtle watermark of App Logo (alpha = 0.055)
let iconUrl = URL(fileURLWithPath: "Resources/AppIcon.png")
if let appIcon = NSImage(contentsOf: iconUrl) {
    cgContext.saveGState()
    cgContext.setAlpha(0.055) // Washed out and faint
    let logoSize: CGFloat = 200
    let logoRect = CGRect(x: (width - logoSize) / 2, y: (height - logoSize) / 2 + 10, width: logoSize, height: logoSize)
    appIcon.draw(in: logoRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    cgContext.restoreGState()
}

// 3. Header Branding
let titleParagraph = NSMutableParagraphStyle()
titleParagraph.alignment = .center

let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.92, alpha: 0.9),
    .paragraphStyle: titleParagraph
]
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 0.8),
    .paragraphStyle: titleParagraph
]

let titleStr = NSAttributedString(string: "OpenArcMouse", attributes: titleAttrs)
titleStr.draw(in: CGRect(x: 0, y: height - 44, width: width, height: 24))

let subStr = NSAttributedString(string: "Drag OpenArcMouse to Applications to install", attributes: subtitleAttrs)
subStr.draw(in: CGRect(x: 0, y: height - 64, width: width, height: 18))

// 4. Coordinates:
// In Finder top-left coordinates:
// App icon: (180, 175) -> In AppKit bottom-left: (180, 400 - 175) = (180, 225)
// Applications: (480, 175) -> In AppKit: (480, 225)
// README text icon: (330, 310) -> In AppKit: (330, 400 - 310) = (330, 90)
let leftCenter = CGPoint(x: 180, y: 225)
let rightCenter = CGPoint(x: 480, y: 225)

func drawTargetHalo(at center: CGPoint) {
    let haloRect = CGRect(x: center.x - 60, y: center.y - 60, width: 120, height: 120)
    let path = NSBezierPath(roundedRect: haloRect, xRadius: 22, yRadius: 22)
    NSColor(calibratedWhite: 1.0, alpha: 0.02).setFill()
    path.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.05).setStroke()
    path.lineWidth = 1.0
    path.stroke()
}

drawTargetHalo(at: leftCenter)
drawTargetHalo(at: rightCenter)

// 5. Drag Arrow pointing from App (180) to Applications (480)
let arrowY: CGFloat = 225
let arrowStartX: CGFloat = 265
let arrowEndX: CGFloat = 385

// Dashed track
let trackPath = NSBezierPath()
trackPath.move(to: CGPoint(x: arrowStartX, y: arrowY))
trackPath.line(to: CGPoint(x: arrowEndX - 8, y: arrowY))
let dashes: [CGFloat] = [5.0, 4.0]
trackPath.setLineDash(dashes, count: 2, phase: 0)
trackPath.lineWidth = 2.5
trackPath.lineCapStyle = .round
NSColor(calibratedRed: 0.35, green: 0.60, blue: 0.95, alpha: 0.45).setStroke()
trackPath.stroke()

// Arrowhead
let headPath = NSBezierPath()
headPath.move(to: CGPoint(x: arrowEndX + 8, y: arrowY))
headPath.line(to: CGPoint(x: arrowEndX - 8, y: arrowY + 9))
headPath.line(to: CGPoint(x: arrowEndX - 4, y: arrowY + 2.5))
headPath.line(to: CGPoint(x: arrowEndX - 12, y: arrowY + 2.5))
headPath.line(to: CGPoint(x: arrowEndX - 12, y: arrowY - 2.5))
headPath.line(to: CGPoint(x: arrowEndX - 4, y: arrowY - 2.5))
headPath.line(to: CGPoint(x: arrowEndX - 8, y: arrowY - 9))
headPath.close()

NSColor(calibratedRed: 0.35, green: 0.60, blue: 0.95, alpha: 0.70).setFill()
headPath.fill()

// Label above arrow
let arrowLabelAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 10, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.40, green: 0.68, blue: 1.0, alpha: 0.70),
    .paragraphStyle: titleParagraph
]
let arrowLabel = NSAttributedString(string: "DRAG ➔", attributes: arrowLabelAttrs)
arrowLabel.draw(in: CGRect(x: 250, y: arrowY + 12, width: 160, height: 16))

// 6. Bottom hint for Gatekeeper notice
let bottomHintAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 10, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.50, alpha: 0.7),
    .paragraphStyle: titleParagraph
]
let bottomHint = NSAttributedString(string: "See instructions below if macOS Gatekeeper blocks opening", attributes: bottomHintAttrs)
bottomHint.draw(in: CGRect(x: 0, y: 18, width: width, height: 16))

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to convert to PNG")
}

let outPath = "Resources/dmg-background.png"
try pngData.write(to: URL(fileURLWithPath: outPath))
print("Successfully generated washed-out DMG background at \(outPath) (\(Int(width))x\(Int(height)))")
