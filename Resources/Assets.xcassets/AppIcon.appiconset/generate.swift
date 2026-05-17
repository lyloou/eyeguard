#!/usr/bin/env swift
// 生成 EyeGuard App Icon — 色板与 ThemeColor.accent / Rest 页 jadeDarkened 对齐。
import AppKit

// MARK: - Palette（与 Sources/Core/ThemeColor.swift 一致）

enum IconPalette {
    /// 翡翠绿强调色
    static let accent = NSColor(red: 0.22, green: 0.78, blue: 0.55, alpha: 1.0)
    /// 略深翡翠（渐变底、瞳孔、内描边）
    static let accentDark = NSColor(red: 0.12, green: 0.52, blue: 0.38, alpha: 1.0)
    /// 渐变高光端、外环描边
    static let accentLight = NSColor(red: 0.30, green: 0.86, blue: 0.62, alpha: 1.0)
    static let sclera = NSColor.white
    static let pupilSpecular = NSColor(white: 1.0, alpha: 0.55)
}

/// 周边修饰强度档位（F3 = 明显）。
private enum DecorIntensity {
  case strong

  /// 内环：白描边不透明度
  var innerRingAlpha: CGFloat { 0.50 }
  /// 外环：浅翡翠描边不透明度
  var outerRingAlpha: CGFloat { 0.45 }
  /// Squircle 内缘描边不透明度
  var insetBorderAlpha: CGFloat { 0.28 }
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

/// 以眼心为圆心描边圆环。
private func strokeRing(
    center: NSPoint,
    radius: CGFloat,
    lineWidth: CGFloat,
    color: NSColor
) {
    let ring = NSBezierPath()
    ring.lineWidth = lineWidth
    color.setStroke()
    ring.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
    ring.stroke()
}

/// Squircle 内缘镶边（方案 3 内描边，与双环配套）。
private func drawSquircleInsetBorder(canvas: NSRect, lineWidth: CGFloat, alpha: CGFloat) {
    let inset = lineWidth / 2
    let border = squirclePath(in: canvas.insetBy(dx: inset, dy: inset))
    border.lineWidth = lineWidth
    IconPalette.accentDark.withAlphaComponent(alpha).setStroke()
    border.stroke()
}

/// 翡翠双环周边修饰（E1）；按尺寸降级。
private func drawPeripheralDecorations(
    size: Int,
    canvas: NSRect,
    eyeCenter: NSPoint,
    eyeWidth: CGFloat,
    intensity: DecorIntensity
) {
    let s = canvas.width
    let scale = s / 1024
    let innerRadius = eyeWidth * 0.62
    let outerRadius = eyeWidth * 0.78

    let insetLW = max(1, 2.5 * scale)
    drawSquircleInsetBorder(
        canvas: canvas,
        lineWidth: insetLW,
        alpha: intensity.insetBorderAlpha
    )

    if size <= 16 {
        return
    }

    if size <= 32 {
        let lw = max(1.5, 5.5 * scale * 1.35)
        strokeRing(
            center: eyeCenter,
            radius: outerRadius,
            lineWidth: lw,
            color: NSColor.white.withAlphaComponent(intensity.innerRingAlpha)
        )
        return
    }

    let boost: CGFloat = size <= 64 ? 1.30 : 1.0
    let innerLW = max(1.5, 7.0 * scale * boost)
    let outerLW = max(1.5, 6.0 * scale * boost)

    strokeRing(
        center: eyeCenter,
        radius: innerRadius,
        lineWidth: innerLW,
        color: NSColor.white.withAlphaComponent(intensity.innerRingAlpha)
    )
    strokeRing(
        center: eyeCenter,
        radius: outerRadius,
        lineWidth: outerLW,
        color: IconPalette.accentLight.withAlphaComponent(intensity.outerRingAlpha)
    )
}

/// 按尺寸返回眼形占画布比例（为双环留出空间）。
private func eyeScaleForIcon(size: Int) -> CGFloat {
    switch size {
    case ...16: return 0.58
    case ...32: return 0.54
    case ...64: return 0.50
    default: return 0.46
    }
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
    let intensity = DecorIntensity.strong

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

    let eyeScale = eyeScaleForIcon(size: size)
    let eyeW = s * eyeScale
    let eyeH = eyeW * (size <= 32 ? 0.46 : 0.42)
    let center = NSPoint(x: s / 2, y: s * 0.50)

    drawPeripheralDecorations(
        size: size,
        canvas: canvas,
        eyeCenter: center,
        eyeWidth: eyeW,
        intensity: intensity
    )

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
