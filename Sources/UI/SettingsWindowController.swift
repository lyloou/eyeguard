import AppKit

/// 设置窗口控制器
class SettingsWindowController: NSObject, NSWindowDelegate {

    static let shared = SettingsWindowController()

    private var window: NSWindow!
    private var workStepper: NSStepper!
    private var workTextField: NSTextField!
    private var restStepper: NSStepper!
    private var restTextField: NSTextField!
    private var enforceCheckbox: NSButton!
    private var pauseOnLockCheckbox: NSButton!
    private var notifyOnWorkEndCheckbox: NSButton!
    private var notifyOnRestEndCheckbox: NSButton!
    private var soundEnabledCheckbox: NSButton!
    private var loginItemCheckbox: NSButton!
    private var statusBarStylePopup: NSPopUpButton!
    private var restWindowPositionPopup: NSPopUpButton!

    private override init() {
        super.init()
        setupWindow()
    }

    // MARK: - Setup

    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 390),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.settingsTitle
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        var y: CGFloat = 240

        // 工作时长
        let workLabel = makeLabel(L10n.workDuration, at: NSPoint(x: 20, y: y))
        contentView.addSubview(workLabel)

        workTextField = makeTextField(editable: false, at: NSPoint(x: 120, y: y - 2))
        contentView.addSubview(workTextField)

        workStepper = NSStepper(frame: NSRect(x: 200, y: y, width: 20, height: 22))
        workStepper.minValue = 1
        workStepper.maxValue = 120
        workStepper.increment = 1
        workStepper.target = self
        workStepper.action = #selector(workStepperChanged)
        contentView.addSubview(workStepper)

        let workUnitLabel = makeLabel(L10n.minutes, at: NSPoint(x: 230, y: y))
        contentView.addSubview(workUnitLabel)

        y -= 40

        // 休息时长
        let restLabel = makeLabel(L10n.restDuration, at: NSPoint(x: 20, y: y))
        contentView.addSubview(restLabel)

        restTextField = makeTextField(editable: false, at: NSPoint(x: 120, y: y - 2))
        contentView.addSubview(restTextField)

        restStepper = NSStepper(frame: NSRect(x: 200, y: y, width: 20, height: 22))
        restStepper.minValue = 1
        restStepper.maxValue = 30
        restStepper.increment = 1
        restStepper.target = self
        restStepper.action = #selector(restStepperChanged)
        contentView.addSubview(restStepper)

        let restUnitLabel = makeLabel(L10n.minutes, at: NSPoint(x: 230, y: y))
        contentView.addSubview(restUnitLabel)

        y -= 40

        // 强制休息
        enforceCheckbox = NSButton(checkboxWithTitle: L10n.enforceRest, target: self, action: #selector(enforceChanged))
        enforceCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(enforceCheckbox)

        y -= 30

        // 锁屏暂停
        pauseOnLockCheckbox = NSButton(checkboxWithTitle: L10n.pauseOnLock, target: self, action: #selector(pauseOnLockChanged))
        pauseOnLockCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(pauseOnLockCheckbox)

        y -= 30

        // 工作结束通知
        notifyOnWorkEndCheckbox = NSButton(checkboxWithTitle: L10n.notifyOnWorkEnd, target: self, action: #selector(notifyOnWorkEndChanged))
        notifyOnWorkEndCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(notifyOnWorkEndCheckbox)

        y -= 30

        // 休息结束通知
        notifyOnRestEndCheckbox = NSButton(checkboxWithTitle: L10n.notifyOnRestEnd, target: self, action: #selector(notifyOnRestEndChanged))
        notifyOnRestEndCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(notifyOnRestEndCheckbox)

        y -= 30

        // 音效
        soundEnabledCheckbox = NSButton(checkboxWithTitle: L10n.soundEnabled, target: self, action: #selector(soundEnabledChanged))
        soundEnabledCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(soundEnabledCheckbox)

        y -= 30

        // 登录启动
        loginItemCheckbox = NSButton(checkboxWithTitle: L10n.loginItem, target: self, action: #selector(loginItemChanged))
        loginItemCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(loginItemCheckbox)

        y -= 30

        // 状态栏样式
        let styleLabel = makeLabel(L10n.statusBarStyle, at: NSPoint(x: 20, y: y))
        contentView.addSubview(styleLabel)

        statusBarStylePopup = NSPopUpButton(frame: NSRect(x: 140, y: y - 2, width: 200, height: 22))
        statusBarStylePopup.addItems(withTitles: [
            L10n.styleClassic,
            L10n.styleMinimal,
            L10n.styleEmoji,
            L10n.styleCompact,
            L10n.styleBracket,
            L10n.styleStar,
            L10n.stylePureTime,
            L10n.styleDots,
            L10n.styleProgressBar
        ])
        statusBarStylePopup.target = self
        statusBarStylePopup.action = #selector(statusBarStyleChanged)
        contentView.addSubview(statusBarStylePopup)

        y -= 30

        // 休息弹窗位置
        let positionLabel = makeLabel(L10n.restWindowPosition, at: NSPoint(x: 20, y: y))
        contentView.addSubview(positionLabel)

        restWindowPositionPopup = NSPopUpButton(frame: NSRect(x: 140, y: y - 2, width: 200, height: 22))
        restWindowPositionPopup.addItems(withTitles: [
            L10n.positionCenter,
            L10n.positionTopRight
        ])
        restWindowPositionPopup.target = self
        restWindowPositionPopup.action = #selector(restWindowPositionChanged)
        contentView.addSubview(restWindowPositionPopup)

        y -= 40

        // 保存按钮
        let saveButton = NSButton(title: L10n.save, target: self, action: #selector(saveClicked))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: window.contentView!.bounds.width - 100, y: 15, width: 80, height: 28)
        saveButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(saveButton)

        loadSettings()
    }

    private func makeLabel(_ text: String, at point: NSPoint) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(origin: point, size: NSSize(width: 100, height: 22))
        label.font = NSFont.systemFont(ofSize: 13)
        return label
    }

    private func makeTextField(editable: Bool, at point: NSPoint) -> NSTextField {
        let field = NSTextField(frame: NSRect(x: point.x, y: point.y, width: 70, height: 22))
        field.isEditable = editable
        field.isSelectable = false
        field.alignment = .right
        field.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        return field
    }

    // MARK: - Load / Save

    private func loadSettings() {
        let s = Settings.shared
        workTextField.integerValue = s.workDuration / 60
        workStepper.integerValue = s.workDuration / 60
        restTextField.integerValue = s.restDuration / 60
        restStepper.integerValue = s.restDuration / 60
        enforceCheckbox.state = s.enforceRest ? .on : .off
        pauseOnLockCheckbox.state = s.pauseOnLock ? .on : .off
        notifyOnWorkEndCheckbox.state = s.notifyOnWorkEnd ? .on : .off
        notifyOnRestEndCheckbox.state = s.notifyOnRestEnd ? .on : .off
        soundEnabledCheckbox.state = s.soundEnabled ? .on : .off
        loginItemCheckbox.state = LoginItemManager.shared.isEnabled ? .on : .off
        statusBarStylePopup.selectItem(at: s.statusBarStyle.index)
        restWindowPositionPopup.selectItem(at: s.restWindowPosition.index)
    }

    @objc private func saveClicked() {
        let s = Settings.shared
        s.workDuration = workTextField.integerValue * 60
        s.restDuration = restTextField.integerValue * 60
        s.enforceRest = (enforceCheckbox.state == .on)
        s.pauseOnLock = (pauseOnLockCheckbox.state == .on)
        s.notifyOnWorkEnd = (notifyOnWorkEndCheckbox.state == .on)
        s.notifyOnRestEnd = (notifyOnRestEndCheckbox.state == .on)
        s.soundEnabled = (soundEnabledCheckbox.state == .on)
        window.close()
    }

    // MARK: - Actions

    @objc private func workStepperChanged() {
        workTextField.integerValue = workStepper.integerValue
        Settings.shared.workDuration = workStepper.integerValue * 60
    }

    @objc private func restStepperChanged() {
        restTextField.integerValue = restStepper.integerValue
        Settings.shared.restDuration = restStepper.integerValue * 60
    }

    @objc private func enforceChanged() {
        Settings.shared.enforceRest = (enforceCheckbox.state == .on)
        NotificationCenter.default.post(name: .settingsDidChange, object: "enforceRest")
    }

    @objc private func pauseOnLockChanged() {
        Settings.shared.pauseOnLock = (pauseOnLockCheckbox.state == .on)
    }

    @objc private func notifyOnWorkEndChanged() {
        Settings.shared.notifyOnWorkEnd = (notifyOnWorkEndCheckbox.state == .on)
    }

    @objc private func notifyOnRestEndChanged() {
        Settings.shared.notifyOnRestEnd = (notifyOnRestEndCheckbox.state == .on)
    }

    @objc private func soundEnabledChanged() {
        Settings.shared.soundEnabled = (soundEnabledCheckbox.state == .on)
    }

    @objc private func loginItemChanged() {
        LoginItemManager.shared.toggle()
    }

    @objc private func statusBarStyleChanged() {
        let index = statusBarStylePopup.indexOfSelectedItem
        Settings.shared.statusBarStyle = Settings.StatusBarStyle.allCases[index]
        NotificationCenter.default.post(name: .settingsDidChange, object: "statusBarStyle")
    }

    @objc private func restWindowPositionChanged() {
        let index = restWindowPositionPopup.indexOfSelectedItem
        Settings.shared.restWindowPosition = Settings.RestWindowPosition.allCases[index]
        NotificationCenter.default.post(name: .settingsDidChange, object: "restWindowPosition")
    }

    // MARK: - Show

    func show() {
        loadSettings()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window.close()
        return true
    }
}
