import AppKit

/// 休息弹窗控制器
class RestWindowController: NSObject {

    private var panel: NSPanel!
    private var countdownLabel: NSTextField!
    private var skipButton: NSButton!
    private var timer: Timer?
    private var localMonitor: Any?

    private weak var manager: TimerManager?

    init(manager: TimerManager) {
        self.manager = manager
        super.init()
        #if DEBUG
        if !Thread.isMainThread {
            fatalError("RestWindowController must be created on main thread")
        }
        #endif
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

    @objc private func settingsDidChange(_ notification: Notification) {
        guard let key = notification.object as? String, key == "enforceRest" else { return }
        updateSkipButtonVisibility()
    }

    private func updateSkipButtonVisibility() {
        skipButton.isHidden = Settings.shared.enforceRest
    }

    // MARK: - Setup

    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 160),
            styleMask: [.closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.hasShadow = false

        // 透明背景
        panel.backgroundColor = .clear
        panel.isOpaque = false

        // 使用 NSVisualEffectView 作为内容背景（带圆角）
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 280, height: 160))
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        panel.contentView = visualEffect

        positionWindow()
    }

    private func positionWindow() {
        let mouseLocation = NSEvent.mouseLocation
        let screenWithMouse = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        guard let screen = screenWithMouse else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        switch Settings.shared.restWindowPosition {
        case .center:
            let x = screenFrame.midX - panelSize.width / 2
            let y = screenFrame.midY - panelSize.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        case .topRight:
            let padding: CGFloat = 20
            let x = screenFrame.maxX - panelSize.width - padding
            let y = screenFrame.maxY - panelSize.height - padding
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    private func setupUI() {
        guard let contentView = panel.contentView else { return }

        // 主标题
        let titleLabel = NSTextField(labelWithString: L10n.restTitle)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // 倒计时
        countdownLabel = NSTextField(labelWithString: "05:00")
        countdownLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        countdownLabel.textColor = .labelColor
        countdownLabel.alignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countdownLabel)

        // 跳过按钮（非强制模式）
        skipButton = NSButton(title: L10n.skipRest, target: self, action: #selector(skipClicked))
        skipButton.bezelStyle = .rounded
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        // 强制模式下隐藏跳过
        if Settings.shared.enforceRest {
            skipButton.isHidden = true
        }
        contentView.addSubview(skipButton)

        // 布局
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            countdownLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -5),
            countdownLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            skipButton.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 12),
            skipButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skipButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
        ])

        // 注册键盘监听（Space / ESC 关闭弹窗）
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 || event.keyCode == 49 { // ESC or Space
                self?.manager?.dismissRestWindow()
                return nil
            }
            return event
        }
    }

    // MARK: - Show / Close

    func show() {
        panel.makeKeyAndOrderFront(nil)
        startCountdown()
        startLocalTimer()
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
        remainingSeconds = Settings.shared.restDuration
        updateCountdownLabel()
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
    }

    // MARK: - Actions

    @objc private func skipClicked() {
        manager?.skipRest()
    }
}
