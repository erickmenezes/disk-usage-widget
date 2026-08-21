import AppKit

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// macOS icons leave breathing room around the rounded body.
let inset: CGFloat = S * 0.085
let body = CGRect(x: inset, y: inset, width: S - inset*2, height: S - inset*2)
let radius = body.width * 0.2237          // Big Sur squircle-ish corner

let path = CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.saveGState()
ctx.addPath(path)
ctx.clip()

// Deep blue gradient background.
let cs = CGColorSpaceCreateDeviceRGB()
let grad = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.15, green: 0.42, blue: 0.85, alpha: 1),
    CGColor(red: 0.06, green: 0.20, blue: 0.55, alpha: 1)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: body.minX, y: body.maxY),
                       end: CGPoint(x: body.maxX, y: body.minY), options: [])
ctx.restoreGState()

// Ring gauge, mirroring the widget: faint full track + bright 70% arc.
let center = CGPoint(x: S/2, y: S/2)
let ringR = S * 0.255
let lw = S * 0.085

ctx.setLineCap(.round)
ctx.setLineWidth(lw)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.22))
ctx.addArc(center: center, radius: ringR, startAngle: 0, endAngle: .pi*2, clockwise: false)
ctx.strokePath()

// 70% used, starting at 12 o'clock going clockwise.
let start = CGFloat.pi/2
let end = start - (.pi * 2 * 0.70)
ctx.setStrokeColor(CGColor(red: 0.30, green: 0.85, blue: 0.39, alpha: 1))
ctx.addArc(center: center, radius: ringR, startAngle: start, endAngle: end, clockwise: true)
ctx.strokePath()

// Drive glyph in the middle.
if let sym = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: nil) {
    // paletteColors tints the glyph itself. Setting a colour and filling the
    // rect with .sourceAtop instead paints the whole bounding box white.
    let cfg = NSImage.SymbolConfiguration(pointSize: S * 0.19, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let tinted = sym.withSymbolConfiguration(cfg) {
        let sz = tinted.size
        let r = NSRect(x: center.x - sz.width/2, y: center.y - sz.height/2,
                       width: sz.width, height: sz.height)
        tinted.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
}

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! png.write(to: URL(fileURLWithPath: "icon_1024.png"))
print("wrote icon_1024.png")
