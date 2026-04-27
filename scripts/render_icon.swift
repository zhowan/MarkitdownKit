import AppKit

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let backgroundRect = NSRect(origin: .zero, size: size)
let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 228, yRadius: 228)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.95, green: 0.86, blue: 0.74, alpha: 1.0),
    NSColor(calibratedRed: 0.77, green: 0.43, blue: 0.24, alpha: 1.0),
])!
gradient.draw(in: backgroundPath, angle: -45)

NSColor(calibratedWhite: 1.0, alpha: 0.16).setFill()
NSBezierPath(ovalIn: NSRect(x: 100, y: 680, width: 320, height: 220)).fill()
NSBezierPath(ovalIn: NSRect(x: 580, y: 120, width: 250, height: 190)).fill()

let paperRect = NSRect(x: 212, y: 176, width: 600, height: 672)
let paperPath = NSBezierPath(roundedRect: paperRect, xRadius: 56, yRadius: 56)
NSColor(calibratedWhite: 0.99, alpha: 1.0).setFill()
paperPath.fill()

NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.16)
shadow.shadowBlurRadius = 26
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
paperPath.fill()
NSGraphicsContext.current?.restoreGraphicsState()

let foldPath = NSBezierPath()
foldPath.move(to: NSPoint(x: 666, y: 848))
foldPath.line(to: NSPoint(x: 812, y: 702))
foldPath.line(to: NSPoint(x: 666, y: 702))
foldPath.close()
NSColor(calibratedRed: 0.93, green: 0.88, blue: 0.81, alpha: 1.0).setFill()
foldPath.fill()

let mdBadgeRect = NSRect(x: 292, y: 520, width: 438, height: 132)
let mdBadge = NSBezierPath(roundedRect: mdBadgeRect, xRadius: 32, yRadius: 32)
NSColor(calibratedRed: 0.76, green: 0.39, blue: 0.22, alpha: 1.0).setFill()
mdBadge.fill()

let badgeShadow = NSShadow()
badgeShadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.08)
badgeShadow.shadowBlurRadius = 12
badgeShadow.shadowOffset = NSSize(width: 0, height: -4)
NSGraphicsContext.current?.saveGraphicsState()
badgeShadow.set()
mdBadge.fill()
NSGraphicsContext.current?.restoreGraphicsState()

let mdText = NSAttributedString(
    string: "MD",
    attributes: [
        .font: NSFont.systemFont(ofSize: 72, weight: .bold),
        .foregroundColor: NSColor.white,
    ]
)
let mdSize = mdText.size()
mdText.draw(at: NSPoint(
    x: mdBadgeRect.midX - mdSize.width / 2,
    y: mdBadgeRect.midY - mdSize.height / 2 + 6
))

func drawLine(y: CGFloat, width: CGFloat, color: NSColor) {
    let rect = NSRect(x: 292, y: y, width: width, height: 22)
    let path = NSBezierPath(roundedRect: rect, xRadius: 11, yRadius: 11)
    color.setFill()
    path.fill()
}

drawLine(y: 452, width: 442, color: NSColor(calibratedRed: 0.81, green: 0.84, blue: 0.87, alpha: 1.0))
drawLine(y: 398, width: 368, color: NSColor(calibratedRed: 0.84, green: 0.87, blue: 0.90, alpha: 1.0))
drawLine(y: 344, width: 264, color: NSColor(calibratedRed: 0.88, green: 0.90, blue: 0.93, alpha: 1.0))

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render icon.\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try pngData.write(to: outputURL)
