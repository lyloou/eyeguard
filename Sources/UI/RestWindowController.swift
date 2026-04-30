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
        setupPanel()
        setupUI()
    }

    // MARK: - Setup

    private func setupPanel() {
        // 创建浮动面板
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 160),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.title = "休息一下"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true

        // 圆角背景
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.isOpaque = false

        // 居中到右上角
        positionToTopRight()
    }

    private func positionToTopRight() {
        // 跟随鼠标所在屏幕的右上角
        let mouseLocation = NSEvent.mouseLocation
        let screenWithMouse = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        guard let screen = screenWithMouse else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let padding: CGFloat = 20

        let x = screenFrame.maxX - panelSize.width - padding
        let y = screenFrame.maxY - panelSize.height - padding
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func setupUI() {
        guard let contentView = panel.contentView else { return }

        // 主标题
        let titleLabel = NSTextField(labelWithString: "休息一下")
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
        skipButton = NSButton(title: "跳过休息", target: self, action: #selector(skipClicked))
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
        updateCountdownLabel()
    }

    // MARK: - Actions

    @objc private func skipClicked() {
        manager?.skipRest()
    }
}
