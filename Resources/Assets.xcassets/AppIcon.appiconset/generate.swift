#!/usr/bin/env swift
// 生成 EyeGuard App Icon — 色板与 ThemeColor.accent / Rest 页 jadeDarkened 对齐。
import AppKit

// MARK: - Palette（与 Sources/Core/ThemeColor.swift 一致）

enum IconPalette {
    /// 翡翠绿强调色
    static let accent = NSColor(red: 0.22, green: 0.78, blue: 0.55, alpha: 1.0)
    /// 略深翡翠（渐变底、瞳孔）
    static let accentDark = NSColor(red: 0.12, green: 0.52, blue: 0.38, alpha: 1.0)
    /// 渐变高光端
    static let accentLight = NSColor(red: 0.30, green: 0.86, blue: 0.62, alpha: 1.0)
    static let sclera = NSColor.white
    static let pupilSpecular = NSColor(white: 1.0, alpha: 0.55)
}

// MARK: - Drawing

/// macOS Squircle 近似圆角（1024 基准约 228pt）。
private func squirclePath(in rect: NSRect) -> NSBezierPath {
    let radius = rect.width * 0.223
    return NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

/// 精炼矢量眼：圆角眼睑 + 瞳孔（纯眼，无休息弧隐喻）。
private func eyeScleraPath(center: NSPoint, width: CGFloat, height: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let left = NSPoint(x: center.x - width / 2, y: center.y)
    let right = NSPoint(x: center.x + width / 2, y: center.y)
    path.move(to: left)
    path.curve(
        to: right,
        controlPoint1: NSPoint(x: center.x - width * 0.36, y: center.y + height * 0.52),
        controlPoint2: NSPoint(x: center.x + width * 0.36, y: center.y + height * 0.52)
    )
    path.curve(
        to: left,
        controlPoint1: NSPoint(x: center.x + width * 0.36, y: center.y - height * 0.48),
        controlPoint2: NSPoint(x: center.x - width * 0.36, y: center.y - height * 0.48)
    )
    path.close()
    return path
}

/// 在 8-bit RGBA 位图上绘制完整图标并写出 PNG。
private func drawIcon(size: Int, to url: URL) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("Failed to create bitmap for \(size)\n", stderr)
        return
    }

    let s = CGFloat(size)
    let canvas = NSRect(x: 0, y: 0, width: s, height: s)
    let detail = size >= 128
    let showHighlight = size >= 64

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx

    let cg = ctx.cgContext
    cg.saveGState()
    squirclePath(in: canvas).addClip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            IconPalette.accentLight.cgColor,
            IconPalette.accent.cgColor,
            IconPalette.accentDark.cgColor,
        ] as CFArray,
        locations: [0.0, 0.48, 1.0]
    )!
    cg.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: s),
        end: CGPoint(x: s, y: 0),
        options: []
    )

    if showHighlight {
        let glowHeight = s * 0.14
        let glowGrad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                NSColor.white.withAlphaComponent(0.22).cgColor,
                NSColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray,
            locations: [0.0, 1.0]
        )!
        cg.drawLinearGradient(
            glowGrad,
            start: CGPoint(x: s / 2, y: s),
            end: CGPoint(x: s / 2, y: s - glowHeight),
            options: []
        )
    }

    cg.restoreGState()

    let eyeScale: CGFloat = size <= 32 ? 0.58 : (size <= 64 ? 0.54 : 0.50)
    let eyeW = s * eyeScale
    let eyeH = eyeW * (size <= 32 ? 0.46 : 0.42)
    let center = NSPoint(x: s / 2, y: s * 0.50)

    let sclera = eyeScleraPath(center: center, width: eyeW, height: eyeH)
    IconPalette.sclera.setFill()
    sclera.fill()

    let pupilR = eyeW * (size <= 32 ? 0.17 : 0.15)
    let pupilCenter = NSPoint(
        x: center.x + eyeW * 0.02,
        y: center.y - eyeH * (size <= 32 ? 0.04 : 0.06)
    )
    let pupil = NSBezierPath(ovalIn: NSRect(
        x: pupilCenter.x - pupilR,
        y: pupilCenter.y - pupilR,
        width: pupilR * 2,
        height: pupilR * 2
    ))
    IconPalette.accentDark.setFill()
    pupil.fill()

    if detail {
        let specR = pupilR * 0.32
        let spec = NSBezierPath(ovalIn: NSRect(
            x: pupilCenter.x - pupilR * 0.35 - specR,
            y: pupilCenter.y + pupilR * 0.28 - specR,
            width: specR * 2,
            height: specR * 2
        ))
        IconPalette.pupilSpecular.setFill()
        spec.fill()
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(
        using: .png,
        properties: [.compressionFactor: 1.0]
    ) else {
        fputs("Failed to encode PNG \(size)\n", stderr)
        return
    }
    try? png.write(to: url)
    print("Generated icon_\(size).png (\(png.count) bytes)")
}

// MARK: - Main

let baseURL = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let url = baseURL.appendingPathComponent("icon_\(size).png")
    drawIcon(size: size, to: url)
}

print("Done — icons written to \(baseURL.path)")
