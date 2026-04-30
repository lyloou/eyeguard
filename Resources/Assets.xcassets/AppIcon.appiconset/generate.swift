#!/usr/bin/env swift
import AppKit

let base = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
    .appendingPathComponent("AppIcon.appiconset")

let sizes = [16, 32, 64, 128, 256, 512, 1024]
var images: [[String: Any]] = []

for size in sizes {
    let filename = "icon_\(size).png"
    let path = base.appendingPathComponent(filename)

    let img = NSImage(size: NSSize(size, size))
    img.lockFocus()

    // Green background
    let green = NSColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0)
    green.setFill()
    NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    // Eye white
    NSColor.white.setFill()
    let eyeRect = NSRect(x: size/5, y: size/3, width: size*3/5, height: size/3)
    NSBezierPath(roundedRect: eyeRect, xRadius: CGFloat(size/10), yRadius: CGFloat(size/10)).fill()

    // Pupil
    green.setFill()
    let pupilRect = NSRect(x: size*2/5, y: size*3/8, width: size/5, height: size/4)
    NSBezierPath(ovalIn: pupilRect).fill()

    img.unlockFocus()

    // Save PNG
    guard let tiff = img.TIFFRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to encode \(filename)")
        continue
    }

    try? png.write(to: path)

    let scale = size >= 64 ? "2x" : "1x"
    let displaySize = size >= 64 ? size/2 : size
    images.append([
        "filename": filename,
        "idiom": "mac",
        "scale": scale,
        "size": "\(displaySize)x\(displaySize)"
    ])

    print("Generated \(filename)")
}

let contents: [String: Any] = [
    "images": images,
    "info": ["version": 1, "author": "xcode"]
]

let jsonData = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
let jsonStr = String(data: jsonData, encoding: .utf8)!
try! jsonStr.write(to: base.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Contents.json written")
