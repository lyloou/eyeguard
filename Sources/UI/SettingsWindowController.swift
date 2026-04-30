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

    private override init() {
        super.init()
        setupWindow()
    }

    // MARK: - Setup

    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "护眼卫士 设置"
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        var y: CGFloat = 200

        // 工作时长
        let workLabel = makeLabel("工作时长:", at: NSPoint(x: 20, y: y))
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

        let workUnitLabel = makeLabel("分钟", at: NSPoint(x: 230, y: y))
        contentView.addSubview(workUnitLabel)

        y -= 40

        // 休息时长
        let restLabel = makeLabel("休息时长:", at: NSPoint(x: 20, y: y))
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

        let restUnitLabel = makeLabel("分钟", at: NSPoint(x: 230, y: y))
        contentView.addSubview(restUnitLabel)

        y -= 40

        // 强制休息
        enforceCheckbox = NSButton(checkboxWithTitle: "强制休息（不允许跳过）", target: self, action: #selector(enforceChanged))
        enforceCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(enforceCheckbox)

        y -= 30

        // 锁屏暂停
        pauseOnLockCheckbox = NSButton(checkboxWithTitle: "锁屏时自动暂停", target: self, action: #selector(pauseOnLockChanged))
        pauseOnLockCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        contentView.addSubview(pauseOnLockCheckbox)

        y -= 40

        // 保存按钮
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveClicked))
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
    }

    @objc private func saveClicked() {
        let s = Settings.shared
        s.workDuration = workTextField.integerValue * 60
        s.restDuration = restTextField.integerValue * 60
        s.enforceRest = (enforceCheckbox.state == .on)
        s.pauseOnLock = (pauseOnLockCheckbox.state == .on)
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
    }

    @objc private func pauseOnLockChanged() {
        Settings.shared.pauseOnLock = (pauseOnLockCheckbox.state == .on)
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
