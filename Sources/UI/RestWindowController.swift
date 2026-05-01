import AppKit
import QuartzCore

/// 休息弹窗控制器 — 呼吸圆环设计
class RestWindowController: NSObject {

    private var panel: NSPanel!
    private var countdownLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var quoteLabel: NSTextField!
    /// 「BREAK」角标，浅色外观需更高对比的强调色。
    private var breakBadgeLabel: NSTextField!
    private var skipButton: NSButton!
    private var ringLayer: CAShapeLayer!
    private var trackLayer: CAShapeLayer!
    private var pulseLayer: CAShapeLayer!
    private var timer: Timer?
    private var localMonitor: Any?

    /// 毛玻璃底板（随系统外观切换材质）
    private var blurBacking: NSVisualEffectView!
    /// 色调叠加层（浅色提亮、深色压暗）
    private var toneOverlay: NSView!

    private weak var manager: TimerManager?
    private var totalSeconds: Int = 0

    init(manager: TimerManager) {
        self.manager = manager
        super.init()
        setupPanel()
        setupUI()
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange(_:)),
            name: .settingsDidChange,
            object: nil
        )
    }

    /// 响应毛玻璃视图有效外观变化，刷新休息窗材质与对比色。
    private func restBackingEffectiveAppearanceChanged() {
        applyRestPanelTone()
    }

    @objc private func settingsDidChange(_ notification: Notification) {
        guard let key = notification.object as? String, key == "enforceRest" else { return }
        updateSkipButtonVisibility()
    }

    private func updateSkipButtonVisibility() {
        skipButton.isHidden = Settings.shared.enforceRest
    }

    /// 从休息弹窗打开设置（与系统 ⌘, 打开「设置 / 偏好设置」一致）。
    private func openSettingsFromRestPanel() {
        SettingsWindowController.shared.show()
    }

    // MARK: - Setup

    private func setupPanel() {
        let w: CGFloat = 360
        let h: CGFloat = 392

        panel = RestPanel(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // 毛玻璃底板（浅色外观下使用更亮、适配的材质）
        let blur = RestVisualEffectView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 20
        blur.layer?.masksToBounds = true
        blur.onEffectiveAppearanceChange = { [weak self] in
            self?.restBackingEffectiveAppearanceChanged()
        }
        panel.contentView = blur
        blurBacking = blur

        let overlay = NSView(frame: blur.bounds)
        overlay.wantsLayer = true
        overlay.layer?.cornerRadius = 20
        blur.addSubview(overlay)
        toneOverlay = overlay

        applyRestPanelTone()
        positionWindow()
    }

    /// 根据当前外观应用休息窗材质、叠色与标签/圆环对比度（浅色偏亮、深色保持 HUD 沉浸感）。
    ///
    /// 在 `setupUI` 完成前仅更新毛玻璃与叠色；控件与图层就绪后会同步文字与圆环颜色。
    private func applyRestPanelTone() {
        guard let blur = blurBacking, let toneLayer = toneOverlay.layer else { return }

        let isDark = blur.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua

        if isDark {
            blur.material = .hudWindow
            toneLayer.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor
        } else {
            blur.material = .popover
            toneLayer.backgroundColor = NSColor.white.withAlphaComponent(0.22).cgColor
        }

        guard let track = trackLayer, let pulse = pulseLayer,
              let subtitle = subtitleLabel, let countdown = countdownLabel,
              let quote = quoteLabel, let skip = skipButton,
              let breakBadge = breakBadgeLabel else { return }

        if isDark {
            track.strokeColor = NSColor.white.withAlphaComponent(0.08).cgColor
            pulse.strokeColor = jadeColor.withAlphaComponent(0.15).cgColor
            subtitle.textColor = NSColor.white.withAlphaComponent(0.45)
            countdown.textColor = NSColor.white.withAlphaComponent(0.92)
            quote.textColor = NSColor.white.withAlphaComponent(0.52)
            breakBadge.textColor = jadeColor.withAlphaComponent(0.85)
            skip.attributedTitle = NSAttributedString(string: "Skip Rest", attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.30),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])
        } else {
            track.strokeColor = NSColor.black.withAlphaComponent(0.10).cgColor
            pulse.strokeColor = jadeColor.withAlphaComponent(0.22).cgColor
            subtitle.textColor = NSColor.secondaryLabelColor
            countdown.textColor = NSColor.labelColor
            quote.textColor = NSColor.secondaryLabelColor
            // 浅色 + 毛玻璃上 tertiary 过淡，用主标签色降透明度保证可读性。
            breakBadge.textColor = jadeDarkenedForLightUI
            skip.attributedTitle = NSAttributedString(string: "Skip Rest", attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.62),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])
        }
    }

    private func positionWindow() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        guard let screen = screen else { return }
        let sf = screen.visibleFrame
        let ps = panel.frame.size

        switch Settings.shared.restWindowPosition {
        case .center:
            panel.setFrameOrigin(NSPoint(x: sf.midX - ps.width / 2, y: sf.midY - ps.height / 2))
        case .topRight:
            let pad: CGFloat = 20
            panel.setFrameOrigin(NSPoint(x: sf.maxX - ps.width - pad, y: sf.maxY - ps.height - pad))
        }
    }

    private func setupUI() {
        guard let contentView = panel.contentView else { return }

        let cx = contentView.bounds.midX
        let cy = contentView.bounds.midY
        let radius: CGFloat = 90

        // Track ring (background arc)
        trackLayer = CAShapeLayer()
        let trackPath = NSBezierPath()
        trackPath.appendArc(withCenter: CGPoint(x: cx, y: cy),
                            radius: radius,
                            startAngle: 90,
                            endAngle: -270,
                            clockwise: true)
        trackLayer.path = trackPath.cgPath
        trackLayer.fillColor = NSColor.clear.cgColor
        trackLayer.strokeColor = NSColor.white.withAlphaComponent(0.08).cgColor
        trackLayer.lineWidth = 6
        trackLayer.lineCap = .round
        contentView.wantsLayer = true
        contentView.layer?.addSublayer(trackLayer)

        // Pulse ring (outer glow, animates)
        pulseLayer = CAShapeLayer()
        pulseLayer.path = trackPath.cgPath
        pulseLayer.fillColor = NSColor.clear.cgColor
        pulseLayer.strokeColor = jadeColor.withAlphaComponent(0.15).cgColor
        pulseLayer.lineWidth = 16
        pulseLayer.lineCap = .round
        contentView.layer?.addSublayer(pulseLayer)

        // Progress ring
        ringLayer = CAShapeLayer()
        ringLayer.path = trackPath.cgPath
        ringLayer.fillColor = NSColor.clear.cgColor
        ringLayer.strokeColor = jadeColor.cgColor
        ringLayer.lineWidth = 5
        ringLayer.lineCap = .round
        ringLayer.strokeStart = 0
        ringLayer.strokeEnd = 1
        contentView.layer?.addSublayer(ringLayer)

        startPulseAnimation()

        // Subtitle (top)
        subtitleLabel = NSTextField(labelWithString: "闭上眼睛 · 好好休息")
        subtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .light)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.45)
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)

        // Countdown
        countdownLabel = NSTextField(labelWithString: "05:00")
        countdownLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 52, weight: .thin)
        countdownLabel.textColor = NSColor.white.withAlphaComponent(0.92)
        countdownLabel.alignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countdownLabel)

        // Random motivational line (below countdown area)
        quoteLabel = NSTextField(wrappingLabelWithString: "")
        quoteLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        quoteLabel.textColor = NSColor.white.withAlphaComponent(0.52)
        quoteLabel.alignment = .center
        quoteLabel.maximumNumberOfLines = 0
        quoteLabel.preferredMaxLayoutWidth = 312
        quoteLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(quoteLabel)

        // "BREAK" label above countdown
        breakBadgeLabel = NSTextField(labelWithString: "BREAK")
        breakBadgeLabel.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        breakBadgeLabel.textColor = jadeColor.withAlphaComponent(0.85)
        breakBadgeLabel.alignment = .center
        breakBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(breakBadgeLabel)

        // Skip button
        skipButton = NSButton(title: "", target: self, action: #selector(skipClicked))
        skipButton.isBordered = false
        skipButton.wantsLayer = true
        skipButton.layer?.cornerRadius = 8
        let skipTitle = NSAttributedString(string: "Skip Rest", attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.3),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])
        skipButton.attributedTitle = skipTitle
        skipButton.isHidden = Settings.shared.enforceRest
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skipButton)

        NSLayoutConstraint.activate([
            // Break label — just above countdown center
            breakBadgeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            breakBadgeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -28),

            // Countdown at center
            countdownLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 4),

            // Subtitle near top
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),

            // Quote between countdown / skip — wrap long Chinese lines
            quoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            quoteLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            quoteLabel.topAnchor.constraint(greaterThanOrEqualTo: countdownLabel.bottomAnchor, constant: 10),
            quoteLabel.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -12),

            // Skip near bottom
            skipButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skipButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])

        // Key monitor: ESC/Space → dismiss; ⌘W → dismiss; ⌘Q → quit; ⌘, → 设置
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let cmd = event.modifierFlags.contains(.command)
            switch (event.keyCode, cmd) {
            case (53, _), (49, _):          // ESC / Space
                self?.manager?.dismissRestWindow()
                return nil
            case (13, true):                // ⌘W
                self?.manager?.dismissRestWindow()
                return nil
            case (12, true):                // ⌘Q
                NSApp.terminate(nil)
                return nil
            case (43, true):                // ⌘, → 设置
                self?.openSettingsFromRestPanel()
                return nil
            default:
                return event
            }
        }

        applyRestPanelTone()
    }

    private var jadeColor: NSColor {
        NSColor(red: 0.22, green: 0.78, blue: 0.55, alpha: 1.0)
    }

    /// 浅色界面上使用的略深翡翠绿，避免半透明 jade 在亮底 + 模糊上发虚。
    private var jadeDarkenedForLightUI: NSColor {
        NSColor(red: 0.12, green: 0.52, blue: 0.38, alpha: 1.0)
    }

    // MARK: - Animations

    private func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.6
        pulse.toValue = 0.0
        pulse.duration = 2.4
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulseLayer.add(pulse, forKey: "pulse")
    }

    private func updateRing(remaining: Int) {
        guard totalSeconds > 0 else { return }
        let progress = CGFloat(remaining) / CGFloat(totalSeconds)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ringLayer.strokeEnd = progress
        CATransaction.commit()
    }

    // MARK: - Show / Close

    func show() {
        applyRestPanelTone()
        quoteLabel.stringValue = RestQuoteProvider.randomQuote()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        startCountdown()
        startLocalTimer()
        animateIn()
    }

    private func animateIn() {
        guard let layer = panel.contentView?.layer else { return }
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.toValue = 1
        fade.duration = 0.35
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(fade, forKey: "fadeIn")

        panel.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        })
    }

    func close() {
        stopLocalTimer()
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        panel.close()
    }

    // MARK: - Countdown

    private var remainingSeconds: Int = 0

    private func startCountdown() {
        totalSeconds = Settings.shared.restDuration
        remainingSeconds = totalSeconds
        updateCountdownLabel()
        updateRing(remaining: remainingSeconds)
    }

    private func updateCountdownLabel() {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        countdownLabel.stringValue = String(format: "%02d:%02d", m, s)
    }

    private func startLocalTimer() {
        stopLocalTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.onTick()
        }
    }

    private func stopLocalTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func onTick() {
        guard remainingSeconds > 0 else {
            stopLocalTimer()
            manager?.restTimerExpired()
            return
        }
        remainingSeconds -= 1
        manager?.updateRestRemaining(remainingSeconds)
        updateCountdownLabel()
        updateRing(remaining: remainingSeconds)
    }

    @objc private func skipClicked() {
        manager?.skipRest()
    }
}

// MARK: - RestPanel（点击时重新夺回 key window）

private class RestPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }
}

/// 在有效外观变化时通知宿主，用于同步毛玻璃材质与前景对比色。
private final class RestVisualEffectView: NSVisualEffectView {
    var onEffectiveAppearanceChange: (() -> Void)?

    /// 转发系统浅色/深色切换，便于更新材质与标签颜色。
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onEffectiveAppearanceChange?()
    }
}

// MARK: - NSBezierPath → CGPath

private extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:  path.move(to: points[0])
            case .lineTo:  path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            default: break
            }
        }
        return path
    }
}
