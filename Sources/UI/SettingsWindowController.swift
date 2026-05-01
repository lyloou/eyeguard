import AppKit

/// 设置窗口控制器 — 分组卡片，明暗自适应
class SettingsWindowController: NSObject, NSWindowDelegate {

    static let shared = SettingsWindowController()

    private var window: NSWindow!
    private var keyMonitor: Any?

    // Timer section
    private var workStepper: NSStepper!
    private var workTextField: NSTextField!
    private var restStepper: NSStepper!
    private var restTextField: NSTextField!

    // Behavior section
    private var enforceSwitch: NSSwitch!
    private var pauseOnLockSwitch: NSSwitch!

    // Notification section
    private var notifyWorkSwitch: NSSwitch!
    private var notifyRestSwitch: NSSwitch!
    private var soundSwitch: NSSwitch!

    // System section
    private var loginSwitch: NSSwitch!
    private var statusBarStylePopup: NSPopUpButton!
    private var restWindowPositionPopup: NSPopUpButton!
    private var themeSegment: NSSegmentedControl!

    private override init() {
        super.init()
        buildWindow()
    }

    // MARK: - Build

    private func buildWindow() {
        let panel = AppPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Settings"
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.center()
        window = panel

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
        ])

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        scroll.documentView = stack

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
        ])

        // ── TIMER ──────────────────────────────────
        stack.addArrangedSubview(sectionHeader("TIMER"))

        let timerCard = makeCard()
        stack.addArrangedSubview(timerCard)
        timerCard.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true

        let timerStack = makeCardStack()
        timerCard.addSubview(timerStack)
        pinCardStack(timerStack, to: timerCard)

        let (workRow, wField, wStepper) = makeDurationRow(label: "Work Duration", unit: "min", min: 1, max: 120, action: #selector(workStepperChanged))
        workTextField = wField
        workStepper = wStepper
        timerStack.addArrangedSubview(workRow)
        workRow.widthAnchor.constraint(equalTo: timerStack.widthAnchor).isActive = true

        timerStack.addArrangedSubview(cardDivider())

        let (restRow, rField, rStepper) = makeDurationRow(label: "Rest Duration", unit: "min", min: 1, max: 30, action: #selector(restStepperChanged))
        restTextField = rField
        restStepper = rStepper
        timerStack.addArrangedSubview(restRow)
        restRow.widthAnchor.constraint(equalTo: timerStack.widthAnchor).isActive = true

        stack.setCustomSpacing(16, after: timerCard)

        // ── BEHAVIOR ───────────────────────────────
        stack.addArrangedSubview(sectionHeader("BEHAVIOR"))

        let behaviorCard = makeCard()
        stack.addArrangedSubview(behaviorCard)
        behaviorCard.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true

        let behaviorStack = makeCardStack()
        behaviorCard.addSubview(behaviorStack)
        pinCardStack(behaviorStack, to: behaviorCard)

        enforceSwitch = NSSwitch()
        enforceSwitch.target = self
        enforceSwitch.action = #selector(enforceChanged)
        behaviorStack.addArrangedSubview(makeSwitchRow(label: "Enforce Rest", subtitle: "Prevent skipping breaks", sw: enforceSwitch))
        behaviorStack.addArrangedSubview(cardDivider())

        pauseOnLockSwitch = NSSwitch()
        pauseOnLockSwitch.target = self
        pauseOnLockSwitch.action = #selector(pauseOnLockChanged)
        behaviorStack.addArrangedSubview(makeSwitchRow(label: "Pause on Lock Screen", subtitle: "Freeze timer when Mac locks", sw: pauseOnLockSwitch))

        for row in behaviorStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: behaviorStack.widthAnchor).isActive = true
        }

        stack.setCustomSpacing(16, after: behaviorCard)

        // ── NOTIFICATIONS ──────────────────────────
        stack.addArrangedSubview(sectionHeader("NOTIFICATIONS"))

        let notifyCard = makeCard()
        stack.addArrangedSubview(notifyCard)
        notifyCard.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true

        let notifyStack = makeCardStack()
        notifyCard.addSubview(notifyStack)
        pinCardStack(notifyStack, to: notifyCard)

        notifyWorkSwitch = NSSwitch()
        notifyWorkSwitch.target = self
        notifyWorkSwitch.action = #selector(notifyWorkChanged)
        notifyStack.addArrangedSubview(makeSwitchRow(label: "Work End Alert", subtitle: "Banner when work session ends", sw: notifyWorkSwitch))
        notifyStack.addArrangedSubview(cardDivider())

        notifyRestSwitch = NSSwitch()
        notifyRestSwitch.target = self
        notifyRestSwitch.action = #selector(notifyRestChanged)
        notifyStack.addArrangedSubview(makeSwitchRow(label: "Rest End Alert", subtitle: "Banner when rest ends", sw: notifyRestSwitch))
        notifyStack.addArrangedSubview(cardDivider())

        soundSwitch = NSSwitch()
        soundSwitch.target = self
        soundSwitch.action = #selector(soundChanged)
        notifyStack.addArrangedSubview(makeSwitchRow(label: "Sound Effects", subtitle: "Play chime on state change", sw: soundSwitch))

        for row in notifyStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: notifyStack.widthAnchor).isActive = true
        }

        stack.setCustomSpacing(16, after: notifyCard)

        // ── SYSTEM ─────────────────────────────────
        stack.addArrangedSubview(sectionHeader("SYSTEM"))

        let sysCard = makeCard()
        stack.addArrangedSubview(sysCard)
        sysCard.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true

        let sysStack = makeCardStack()
        sysCard.addSubview(sysStack)
        pinCardStack(sysStack, to: sysCard)

        loginSwitch = NSSwitch()
        loginSwitch.target = self
        loginSwitch.action = #selector(loginChanged)
        sysStack.addArrangedSubview(makeSwitchRow(label: "Launch at Login", subtitle: "Start automatically on boot", sw: loginSwitch))
        sysStack.addArrangedSubview(cardDivider())

        statusBarStylePopup = makePopup(
            items: Settings.StatusBarStyle.allCases.map { styleDisplayName($0) },
            action: #selector(styleChanged)
        )
        sysStack.addArrangedSubview(makePopupRow(label: "Status Bar Style", popup: statusBarStylePopup))
        sysStack.addArrangedSubview(cardDivider())

        restWindowPositionPopup = makePopup(
            items: [L10n.positionCenter, L10n.positionTopRight],
            action: #selector(positionChanged)
        )
        sysStack.addArrangedSubview(makePopupRow(label: "Break Window Position", popup: restWindowPositionPopup))
        sysStack.addArrangedSubview(cardDivider())

        themeSegment = NSSegmentedControl(
            labels: ["System", "Light", "Dark"],
            trackingMode: .selectOne,
            target: self,
            action: #selector(themeChanged)
        )
        themeSegment.segmentStyle = .rounded
        themeSegment.translatesAutoresizingMaskIntoConstraints = false
        sysStack.addArrangedSubview(makeSegmentRow(label: "Appearance", segment: themeSegment))

        for row in sysStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: sysStack.widthAnchor).isActive = true
        }

        loadSettings()
    }

    // MARK: - Card Builder Helpers

    private func makeCard() -> NSView {
        let card = ThemeAdaptiveView()
        card.lightColor = ThemeColor.cardBackground
        card.darkColor  = ThemeColor.cardBackground
        card.wantsLayer = true
        card.layer?.cornerRadius = 10
        card.layer?.borderWidth = 0.5
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    private func makeCardStack() -> NSStackView {
        let s = NSStackView()
        s.orientation = .vertical
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    private func pinCardStack(_ stack: NSStackView, to card: NSView) {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4),
        ])
    }

    private func sectionHeader(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = NSColor.secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let wrapper = NSView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 4),
            label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -4),
            label.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            wrapper.heightAnchor.constraint(equalToConstant: 24),
        ])
        return wrapper
    }

    private func cardDivider() -> NSView {
        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.separatorColor.cgColor
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return line
    }

    private func makeDurationRow(label: String, unit: String, min: Int, max: Int, action: Selector)
        -> (NSView, NSTextField, NSStepper) {

        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let lbl = rowLabel(label)
        row.addSubview(lbl)

        let field = NSTextField(frame: .zero)
        field.isEditable = false
        field.isSelectable = false
        field.alignment = .right
        field.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        field.textColor = ThemeColor.accent
        field.isBordered = false
        field.drawsBackground = false
        field.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(field)

        let stepper = NSStepper()
        stepper.minValue = Double(min)
        stepper.maxValue = Double(max)
        stepper.increment = 1
        stepper.target = self
        stepper.action = action
        stepper.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stepper)

        let unitLbl = NSTextField(labelWithString: unit)
        unitLbl.font = NSFont.systemFont(ofSize: 11)
        unitLbl.textColor = .tertiaryLabelColor
        unitLbl.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(unitLbl)

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            stepper.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            stepper.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            unitLbl.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -6),
            unitLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            field.trailingAnchor.constraint(equalTo: unitLbl.leadingAnchor, constant: -4),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 36),
        ])

        return (row, field, stepper)
    }

    private func makeSwitchRow(label: String, subtitle: String, sw: NSSwitch) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let lbl = rowLabel(label)
        row.addSubview(lbl)

        let sub = NSTextField(labelWithString: subtitle)
        sub.font = NSFont.systemFont(ofSize: 11)
        sub.textColor = .secondaryLabelColor
        sub.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(sub)

        sw.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(sw)

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),

            sub.leadingAnchor.constraint(equalTo: lbl.leadingAnchor),
            sub.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 2),

            sw.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            sw.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        return row
    }

    private func makePopup(items: [String], action: Selector) -> NSPopUpButton {
        let popup = NSPopUpButton()
        popup.addItems(withTitles: items)
        popup.target = self
        popup.action = action
        popup.font = NSFont.systemFont(ofSize: 12)
        popup.translatesAutoresizingMaskIntoConstraints = false
        return popup
    }

    private func makePopupRow(label: String, popup: NSPopUpButton) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let lbl = rowLabel(label)
        row.addSubview(lbl)
        row.addSubview(popup)

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            popup.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            popup.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 170),
        ])

        return row
    }

    private func makeSegmentRow(label: String, segment: NSSegmentedControl) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let lbl = rowLabel(label)
        row.addSubview(lbl)
        row.addSubview(segment)

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            segment.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            segment.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            segment.widthAnchor.constraint(equalToConstant: 170),
        ])

        return row
    }

    private func rowLabel(_ text: String) -> NSTextField {
        let lbl = NSTextField(labelWithString: text)
        lbl.font = NSFont.systemFont(ofSize: 13)
        lbl.textColor = .labelColor
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    private func styleDisplayName(_ style: Settings.StatusBarStyle) -> String {
        switch style {
        case .classic:     return "Classic"
        case .minimal:     return "Minimal"
        case .emoji:       return "Emoji"
        case .compact:     return "Compact"
        case .bracket:     return "Bracket"
        case .star:        return "Star"
        case .dots:        return "Dots"
        case .progressBar: return "Progress Bar"
        }
    }

    // MARK: - Load Settings

    private func loadSettings() {
        let s = Settings.shared
        workTextField.integerValue = s.workDuration / 60
        workStepper.integerValue   = s.workDuration / 60
        restTextField.integerValue = s.restDuration / 60
        restStepper.integerValue   = s.restDuration / 60

        enforceSwitch.state      = s.enforceRest      ? .on : .off
        pauseOnLockSwitch.state  = s.pauseOnLock      ? .on : .off
        notifyWorkSwitch.state   = s.notifyOnWorkEnd  ? .on : .off
        notifyRestSwitch.state   = s.notifyOnRestEnd  ? .on : .off
        soundSwitch.state        = s.soundEnabled     ? .on : .off
        loginSwitch.state        = LoginItemManager.shared.isEnabled ? .on : .off
        statusBarStylePopup.selectItem(at: s.statusBarStyle.index)
        restWindowPositionPopup.selectItem(at: s.restWindowPosition.index)
        themeSegment.selectedSegment = s.themeMode.index
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
        Settings.shared.enforceRest = (enforceSwitch.state == .on)
        NotificationCenter.default.post(name: .settingsDidChange, object: "enforceRest")
    }

    @objc private func pauseOnLockChanged() {
        Settings.shared.pauseOnLock = (pauseOnLockSwitch.state == .on)
    }

    @objc private func notifyWorkChanged() {
        Settings.shared.notifyOnWorkEnd = (notifyWorkSwitch.state == .on)
    }

    @objc private func notifyRestChanged() {
        Settings.shared.notifyOnRestEnd = (notifyRestSwitch.state == .on)
    }

    @objc private func soundChanged() {
        Settings.shared.soundEnabled = (soundSwitch.state == .on)
    }

    @objc private func loginChanged() {
        LoginItemManager.shared.toggle()
    }

    @objc private func styleChanged() {
        let idx = statusBarStylePopup.indexOfSelectedItem
        Settings.shared.statusBarStyle = Settings.StatusBarStyle.allCases[idx]
        NotificationCenter.default.post(name: .settingsDidChange, object: "statusBarStyle")
    }

    @objc private func positionChanged() {
        let idx = restWindowPositionPopup.indexOfSelectedItem
        Settings.shared.restWindowPosition = Settings.RestWindowPosition.allCases[idx]
        NotificationCenter.default.post(name: .settingsDidChange, object: "restWindowPosition")
    }

    @objc private func themeChanged() {
        let mode = Settings.ThemeMode.allCases[themeSegment.selectedSegment]
        Settings.shared.themeMode = mode
        NotificationCenter.default.post(name: .settingsDidChange, object: "themeMode")
    }

    // MARK: - Show / NSWindowDelegate

    func show() {
        loadSettings()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func windowWillClose(_ notification: Notification) {
        removeKeyMonitor()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains(.command) else { return event }
            switch event.keyCode {
            case 13: self?.window.close(); return nil   // ⌘W
            case 12: NSApp.terminate(nil); return nil   // ⌘Q
            default: return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

// MARK: - Theme-adaptive card view

/// NSView 子类，在 `updateLayer` 时根据当前 appearance 设置背景和边框色
private class ThemeAdaptiveView: NSView {

    var lightColor: NSColor = .clear
    var darkColor: NSColor  = .clear

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        layer?.backgroundColor = (isDark ? darkColor : lightColor).cgColor
        layer?.borderColor     = ThemeColor.cardBorder.resolvedColor(with: effectiveAppearance).cgColor
    }
}

// MARK: - NSColor helper

private extension NSColor {
    func resolvedColor(with appearance: NSAppearance) -> NSColor {
        var resolved = self
        appearance.performAsCurrentDrawingAppearance {
            resolved = self.usingColorSpace(.deviceRGB) ?? self
        }
        return resolved
    }
}
