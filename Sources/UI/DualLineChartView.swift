import AppKit

/// 双折线图数据点（Y 轴单位为分钟）。
struct DualLineChartPoint {
    let label: String
    let workMinutes: Double
    let restMinutes: Double
}

/// 在同一坐标系内绘制工作与休息两条折线（含区域填充）。
final class DualLineChartView: NSView {

    var points: [DualLineChartPoint] = [] {
        didSet { needsDisplay = true }
    }

    var workLegendTitle: String = ""
    var restLegendTitle: String = ""
    var emptyMessage: String = ""
    var yAxisUnit: String = ""

    private let plotInsets = NSEdgeInsets(top: 40, left: 48, bottom: 32, right: 20)

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let plotRect = plotArea(in: bounds)
        drawLegend(in: bounds)

        guard !points.isEmpty else {
            drawEmptyState(in: plotRect)
            return
        }

        let workValues = points.map(\.workMinutes)
        let restValues = points.map(\.restMinutes)
        let maxValue = max(workValues.max() ?? 0, restValues.max() ?? 0, 1)
        let yMax = niceCeiling(maxValue)

        drawPlotBackground(in: plotRect)
        drawHorizontalGrid(in: plotRect, yMax: yMax, context: ctx)
        drawAxes(in: plotRect, context: ctx)
        drawYLabels(in: plotRect, yMax: yMax)
        drawXLabels(in: plotRect)

        ctx.saveGState()
        ctx.clip(to: plotRect)

        if hasNonZero(workValues) {
            drawArea(in: plotRect, values: workValues, yMax: yMax, fill: ThemeColor.accent.withAlphaComponent(0.14))
            drawLine(in: plotRect, values: workValues, yMax: yMax, stroke: ThemeColor.accent)
            drawDots(in: plotRect, values: workValues, yMax: yMax, color: ThemeColor.accent)
        }

        if hasNonZero(restValues) {
            drawArea(in: plotRect, values: restValues, yMax: yMax, fill: ThemeColor.chartRest.withAlphaComponent(0.12))
            drawLine(in: plotRect, values: restValues, yMax: yMax, stroke: ThemeColor.chartRest)
            drawDots(in: plotRect, values: restValues, yMax: yMax, color: ThemeColor.chartRest)
        }

        ctx.restoreGState()
    }

    // MARK: - Layout

    private func plotArea(in rect: NSRect) -> NSRect {
        NSRect(
            x: rect.minX + plotInsets.left,
            y: rect.minY + plotInsets.bottom,
            width: max(1, rect.width - plotInsets.left - plotInsets.right),
            height: max(1, rect.height - plotInsets.top - plotInsets.bottom)
        )
    }

    private func niceCeiling(_ value: Double) -> Double {
        let floor = max(value, 1)
        let candidates: [Double] = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 360, 480, 720]
        if let match = candidates.first(where: { $0 >= floor }) { return match }
        return ceil(floor / 120) * 120
    }

    private func hasNonZero(_ values: [Double]) -> Bool {
        values.contains { $0 > 0 }
    }

    // MARK: - Drawing

    private func drawPlotBackground(in plotRect: NSRect) {
        let path = NSBezierPath(roundedRect: plotRect, xRadius: 6, yRadius: 6)
        ThemeColor.chartPlotBackground.setFill()
        path.fill()
    }

    private func drawLegend(in rect: NSRect) {
        var x = plotInsets.left
        x = drawLegendItem(title: workLegendTitle, color: ThemeColor.accent, at: CGPoint(x: x, y: 14))
        _ = drawLegendItem(title: restLegendTitle, color: ThemeColor.chartRest, at: CGPoint(x: x + 20, y: 14))
        _ = rect
    }

    @discardableResult
    private func drawLegendItem(title: String, color: NSColor, at origin: CGPoint) -> CGFloat {
        let dotRect = NSRect(x: origin.x, y: origin.y + 1, width: 8, height: 8)
        color.setFill()
        NSBezierPath(ovalIn: dotRect).fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let size = (title as NSString).size(withAttributes: attrs)
        (title as NSString).draw(at: NSPoint(x: origin.x + 12, y: origin.y - 1), withAttributes: attrs)
        return origin.x + 12 + size.width
    }

    /// 分别绘制底边与左边轴线，避免连成对角线。
    private func drawAxes(in plotRect: NSRect, context: CGContext) {
        context.setStrokeColor(NSColor.separatorColor.withAlphaComponent(0.8).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
        context.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.minY))
        context.strokePath()
        context.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
        context.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
        context.strokePath()
    }

    private func drawHorizontalGrid(in plotRect: NSRect, yMax: Double, context: CGContext) {
        let steps = 4
        context.setStrokeColor(NSColor.separatorColor.withAlphaComponent(0.22).cgColor)
        context.setLineWidth(0.5)
        for i in 1...steps {
            let y = plotRect.maxY - plotRect.height * CGFloat(i) / CGFloat(steps)
            context.move(to: CGPoint(x: plotRect.minX, y: y))
            context.addLine(to: CGPoint(x: plotRect.maxX, y: y))
            context.strokePath()
        }
        _ = yMax
    }

    private func drawYLabels(in plotRect: NSRect, yMax: Double) {
        let steps = 4
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        for i in 0...steps {
            let value = Int(yMax * Double(i) / Double(steps))
            let text = "\(value)"
            let y = plotRect.maxY - plotRect.height * CGFloat(i) / CGFloat(steps)
            (text as NSString).draw(
                at: NSPoint(x: plotRect.minX - 40, y: y - 6),
                withAttributes: attrs
            )
        }
        if !yAxisUnit.isEmpty {
            let unitAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: NSColor.tertiaryLabelColor,
            ]
            (yAxisUnit as NSString).draw(
                at: NSPoint(x: plotRect.minX - 40, y: plotRect.minY - 18),
                withAttributes: unitAttrs
            )
        }
    }

    private func drawXLabels(in plotRect: NSRect) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        let count = points.count
        let step = count <= 14 ? 1 : max(1, count / 7)
        for (index, point) in points.enumerated() where index % step == 0 || index == count - 1 {
            let x = xPosition(for: index, count: count, in: plotRect)
            let size = (point.label as NSString).size(withAttributes: attrs)
            (point.label as NSString).draw(
                at: NSPoint(x: x - size.width / 2, y: plotRect.maxY + 8),
                withAttributes: attrs
            )
        }
    }

    private func drawEmptyState(in plotRect: NSRect) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let size = (emptyMessage as NSString).size(withAttributes: attrs)
        (emptyMessage as NSString).draw(
            at: NSPoint(x: plotRect.midX - size.width / 2, y: plotRect.midY - size.height / 2),
            withAttributes: attrs
        )
    }

    private func drawArea(in plotRect: NSRect, values: [Double], yMax: Double, fill: NSColor) {
        guard values.count > 1 else { return }
        let path = linePath(in: plotRect, values: values, yMax: yMax, closeToBaseline: true)
        fill.setFill()
        path.fill()
    }

    private func drawLine(in plotRect: NSRect, values: [Double], yMax: Double, stroke: NSColor) {
        let path = linePath(in: plotRect, values: values, yMax: yMax, closeToBaseline: false)
        stroke.setStroke()
        path.lineWidth = 2.25
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    private func linePath(
        in plotRect: NSRect,
        values: [Double],
        yMax: Double,
        closeToBaseline: Bool
    ) -> NSBezierPath {
        let path = NSBezierPath()
        guard !values.isEmpty else { return path }

        for (index, value) in values.enumerated() {
            let point = plotPoint(at: index, count: values.count, value: value, yMax: yMax, in: plotRect)
            if index == 0 { path.move(to: point) } else { path.line(to: point) }
        }

        if closeToBaseline, values.count > 1 {
            let lastX = xPosition(for: values.count - 1, count: values.count, in: plotRect)
            let firstX = xPosition(for: 0, count: values.count, in: plotRect)
            path.line(to: NSPoint(x: lastX, y: plotRect.maxY))
            path.line(to: NSPoint(x: firstX, y: plotRect.maxY))
            path.close()
        }
        return path
    }

    private func drawDots(in plotRect: NSRect, values: [Double], yMax: Double, color: NSColor) {
        for (index, value) in values.enumerated() where value > 0 {
            let center = plotPoint(at: index, count: values.count, value: value, yMax: yMax, in: plotRect)
            let outer = NSBezierPath(ovalIn: NSRect(x: center.x - 4.5, y: center.y - 4.5, width: 9, height: 9))
            NSColor.controlBackgroundColor.withAlphaComponent(0.9).setFill()
            outer.fill()
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)).fill()
        }
    }

    private func plotPoint(at index: Int, count: Int, value: Double, yMax: Double, in plotRect: NSRect) -> NSPoint {
        let x = xPosition(for: index, count: count, in: plotRect)
        let ratio = yMax > 0 ? value / yMax : 0
        let y = plotRect.maxY - plotRect.height * CGFloat(ratio)
        return NSPoint(x: x, y: y)
    }

    private func xPosition(for index: Int, count: Int, in plotRect: NSRect) -> CGFloat {
        guard count > 1 else { return plotRect.midX }
        return plotRect.minX + plotRect.width * CGFloat(index) / CGFloat(count - 1)
    }
}
