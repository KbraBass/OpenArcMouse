import AppKit
import CoreImage
import Foundation

// Canvas dimensions matching DMG window (660 x 620)
let width: CGFloat = 660
let height: CGFloat = 620

// Target window width & height
let winW: CGFloat = 660
let winH: CGFloat = 620
let contentCenter: CGFloat = 330 // Horizontal center of 660px window

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

// 1. Sleek Dark Charcoal / Slate Gradient Background across the FULL 1100x750 canvas
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradientColors = [
    NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.10, alpha: 1.0).cgColor
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

// 2. Large, Heavily Discolored Logo Watermark
let iconUrl = URL(fileURLWithPath: "Resources/AppIcon.png")
if let image = NSImage(contentsOf: iconUrl),
   let tiffData = image.tiffRepresentation,
   let ciImage = CIImage(data: tiffData) {
    let filter = CIFilter(name: "CIColorControls")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(0.0, forKey: kCIInputSaturationKey) // Full monochrome
    filter.setValue(-0.62, forKey: kCIInputBrightnessKey) // Darken highlights to dark charcoal
    filter.setValue(1.10, forKey: kCIInputContrastKey)

    let ciContext = CIContext()
    if let output = filter.outputImage,
       let filteredCG = ciContext.createCGImage(output, from: output.extent) {
        cgContext.saveGState()
        cgContext.setAlpha(0.09) // Subtle watermark
        let logoSize: CGFloat = 340
        let logoRect = CGRect(
            x: contentCenter - (logoSize / 2),
            y: height - 420,
            width: logoSize,
            height: logoSize
        )
        cgContext.draw(filteredCG, in: logoRect)
        cgContext.restoreGState()
    }
}

// 3. Header: Title & Subtitle
let centerParagraph = NSMutableParagraphStyle()
centerParagraph.alignment = .center

let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .bold),
    .foregroundColor: NSColor.white,
    .paragraphStyle: centerParagraph
]
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.70, alpha: 0.9),
    .paragraphStyle: centerParagraph
]

let titleY = height - 38
let titleStr = NSAttributedString(string: "OpenArcMouse", attributes: titleAttrs)
titleStr.draw(in: CGRect(x: 0, y: titleY, width: winW, height: 26))

let subY = height - 64
let subStr = NSAttributedString(string: "Drag OpenArcMouse to Applications to install", attributes: subtitleAttrs)
subStr.draw(in: CGRect(x: 0, y: subY, width: winW, height: 20))

// 4. Coordinates for Icons (y_finder = 145 -> y_appkit = height - 145)
let iconsY = height - 145
let leftCenter = CGPoint(x: 170, y: iconsY)
let rightCenter = CGPoint(x: 490, y: iconsY)

func drawTargetHalo(at center: CGPoint) {
    let haloRect = CGRect(x: center.x - 48, y: center.y - 48, width: 96, height: 96)
    let path = NSBezierPath(roundedRect: haloRect, xRadius: 20, yRadius: 20)
    NSColor(calibratedWhite: 1.0, alpha: 0.03).setFill()
    path.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.08).setStroke()
    path.lineWidth = 1.0
    path.stroke()
}

drawTargetHalo(at: leftCenter)
drawTargetHalo(at: rightCenter)

// 5. HIGH-CONTRAST Drag Arrow between App (170) and Applications (490)
let arrowY = iconsY
let arrowStartX: CGFloat = 235
let arrowEndX: CGFloat = 415

// Arrow track
let trackPath = NSBezierPath()
trackPath.move(to: CGPoint(x: arrowStartX, y: arrowY))
trackPath.line(to: CGPoint(x: arrowEndX - 8, y: arrowY))
let dashes: [CGFloat] = [6.0, 4.0]
trackPath.setLineDash(dashes, count: 2, phase: 0)
trackPath.lineWidth = 3.0
trackPath.lineCapStyle = .round
NSColor(calibratedRed: 0.20, green: 0.65, blue: 1.0, alpha: 0.85).setStroke()
trackPath.stroke()

// Bold Arrowhead
let headPath = NSBezierPath()
headPath.move(to: CGPoint(x: arrowEndX + 8, y: arrowY))
headPath.line(to: CGPoint(x: arrowEndX - 8, y: arrowY + 10))
headPath.line(to: CGPoint(x: arrowEndX - 4, y: arrowY + 3))
headPath.line(to: CGPoint(x: arrowEndX - 14, y: arrowY + 3))
headPath.line(to: CGPoint(x: arrowEndX - 14, y: arrowY - 3))
headPath.line(to: CGPoint(x: arrowEndX - 4, y: arrowY - 3))
headPath.line(to: CGPoint(x: arrowEndX - 8, y: arrowY - 10))
headPath.close()

NSColor(calibratedRed: 0.20, green: 0.65, blue: 1.0, alpha: 0.95).setFill()
headPath.fill()

// Pill Badge above Arrow
let pillRect = CGRect(x: contentCenter - 55, y: arrowY + 14, width: 110, height: 22)
let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 11, yRadius: 11)
NSColor(calibratedRed: 0.05, green: 0.35, blue: 0.85, alpha: 0.35).setFill()
pillPath.fill()
NSColor(calibratedRed: 0.20, green: 0.65, blue: 1.0, alpha: 0.65).setStroke()
pillPath.lineWidth = 1.0
pillPath.stroke()

let pillAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 10, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.55, green: 0.85, blue: 1.0, alpha: 1.0),
    .paragraphStyle: centerParagraph
]
let pillStr = NSAttributedString(string: "DRAG ➔", attributes: pillAttrs)
pillStr.draw(in: CGRect(x: pillRect.origin.x, y: pillRect.origin.y + 4, width: pillRect.width, height: 14))

// 6. Bottom Terminal Hint Box
// Placed at y_finder = 375 to 425 -> y_appkit = height - 425 = 325
// Leaves 135+ pixels of clearance above the bottom of the 560px window!
let boxY = height - 428
let boxRect = CGRect(x: contentCenter - 270, y: boxY, width: 540, height: 48)
let boxPath = NSBezierPath(roundedRect: boxRect, xRadius: 8, yRadius: 8)
NSColor(calibratedWhite: 0.15, alpha: 0.60).setFill()
boxPath.fill()
NSColor(calibratedWhite: 1.0, alpha: 0.10).setStroke()
boxPath.lineWidth = 1.0
boxPath.stroke()

let boxHintAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.70, alpha: 0.9),
    .paragraphStyle: centerParagraph
]
let boxCmdAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.55, alpha: 1.0), // Terminal Green
    .paragraphStyle: centerParagraph
]

let boxHint = NSAttributedString(string: "If blocked by macOS on first launch, open Terminal and run:", attributes: boxHintAttrs)
boxHint.draw(in: CGRect(x: boxRect.origin.x, y: boxRect.origin.y + 25, width: boxRect.width, height: 16))

let boxCmd = NSAttributedString(string: "xattr -cr /Applications/OpenArcMouse.app", attributes: boxCmdAttrs)
boxCmd.draw(in: CGRect(x: boxRect.origin.x, y: boxRect.origin.y + 7, width: boxRect.width, height: 18))

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to convert to PNG")
}

let outPath = "Resources/dmg-background.png"
try pngData.write(to: URL(fileURLWithPath: outPath))
print("Successfully generated taller dark DMG background at \(outPath) (\(Int(width))x\(Int(height)))")
