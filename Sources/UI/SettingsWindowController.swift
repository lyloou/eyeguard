import AppKit

/// 设置窗口控制器 — 分组卡片，明暗自适应
class SettingsWindowController: NSObject, NSWindowDelegate {

    static let shared = SettingsWindowController()

    private var window: NSWindow!
    private var keyMonitor: Any?
    private var titleTopConstraint: NSLayoutConstraint!
    private var settingsHeaderLabel: NSTextField!

    // Timer section
    private var workStepper: NSStepper!
    private var workTextField: NSTextField!
    private var restStepper: NSStepper!
    private var restTextField: NSTextField!

    // Behavior section
    private var enforceSwitch: NSSwitch!
    private var restWindowAutoActivateSwitch: NSSwitch!
    private var waitForActivityAfterRestSwitch: NSSwitch!
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
    private var languagePopup: NSPopUpButton!

    // Shortcuts section
    private var toggleHotkeyRecordButton: NSButton!
    private var toggleHotkeyClearButton: NSButton!
    private var restHotkeyRecordButton: NSButton!
    private var restHotkeyClearButton: NSButton!

    /// 正在录制快捷键的目标槽位（nil 表示未在录制）
    private var hotkeyRecordingSlot: HotkeyRecordingSlot?

    private enum HotkeyRecordingSlot {
        case toggle
        case restNow
    }

    private override init() {
        super.init()
        buildWindow()
    }

    // MARK: - Build

    private func buildWindow() {
        let panel = AppPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 640),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.settingsTitle
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        EyeGuardWindowChrome.configure(panel: panel)
        panel.center()
        window = panel

        guard let contentView = window.contentView else { return }
        let blur = EyeGuardWindowChrome.installBackground(on: contentView)
        _ = EyeGuardWindowChrome.addTopGlow(to: blur)

        settingsHeaderLabel = NSTextField(labelWithString: "")
        settingsHeaderLabel.lineBreakMode = .byTruncatingTail
        settingsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(settingsHeaderLabel)
        updateSettingsHeader()

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.horizontalScrollElasticity = .none
        scroll.verticalScrollElasticity = .allowed
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(scroll)

        titleTopConstraint = settingsHeaderLabel.topAnchor.constraint(equalTo: blur.topAnchor, constant: 52)

        NSLayoutConstraint.activate([
            titleTopConstraint,
            settingsHeaderLabel.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 78),
            settingsHeaderLabel.trailingAnchor.constraint(lessThanOrEqualTo: blur.trailingAnchor, constant: -20),

            scroll.topAnchor.constraint(equalTo: settingsHeaderLabel.bottomAnchor, constant: 14),
            scroll.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
        ])

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 20, bottom: 24, right: 20)
        /// 纵向由子视图撑开高度，避免把文档底钉在 clipView 上（那样会拉高窗口、不会出现滚动条）
        stack.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        scroll.documentView = stack

        let clipView = scroll.contentView
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: clipView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            stack.widthAnchor.constraint(equalTo: clipView.widthAnchor),
        ])

        // ── SYSTEM ─────────────────────────────────
        stack.addArrangedSubview(sectionHeader("settings.section.system"))

        let sysCard = makeCard()
        stack.addArrangedSubview(sysCard)
        sysCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let sysStack = makeCardStack()
        sysCard.addSubview(sysStack)
        pinCardStack(sysStack, to: sysCard)

        languagePopup = makePopup(items: languagePopupTitles(), action: #selector(languageChanged))
        sysStack.addArrangedSubview(makePopupRow(labelKey: "settings.language.label", popup: languagePopup))
        sysStack.addArrangedSubview(cardDivider())

        loginSwitch = NSSwitch()
        loginSwitch.target = self
        loginSwitch.action = #selector(loginChanged)
        sysStack.addArrangedSubview(makeSwitchRow(labelKey: "settings.launchAtLogin.label", subtitleKey: "settings.launchAtLogin.subtitle", sw: loginSwitch))
        sysStack.addArrangedSubview(cardDivider())

        statusBarStylePopup = makePopup(
            items: Settings.StatusBarStyle.allCases.map { styleDisplayName($0) },
            action: #selector(styleChanged)
        )
        sysStack.addArrangedSubview(makePopupRow(labelKey: "settings.statusBarStyle.label", popup: statusBarStylePopup))
        sysStack.addArrangedSubview(cardDivider())

        restWindowPositionPopup = makePopup(
            items: [L10n.positionCenter, L10n.positionTopRight],
            action: #selector(positionChanged)
        )
        sysStack.addArrangedSubview(makePopupRow(labelKey: "settings.breakWindowPosition.label", popup: restWindowPositionPopup))
        sysStack.addArrangedSubview(cardDivider())

        themeSegment = NSSegmentedControl(
            labels: [L10n.themeSystem, L10n.themeLight, L10n.themeDark],
            trackingMode: .selectOne,
            target: self,
            action: #selector(themeChanged)
        )
        themeSegment.segmentStyle = .rounded
        themeSegment.translatesAutoresizingMaskIntoConstraints = false
        sysStack.addArrangedSubview(makeSegmentRow(labelKey: "settings.appearance.label", segment: themeSegment))

        for row in sysStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: sysStack.widthAnchor).isActive = true
        }

        stack.setCustomSpacing(16, after: sysCard)

        // ── SHORTCUTS ───────────────────────────────
        stack.addArrangedSubview(sectionHeader("settings.section.shortcuts"))

        let shortcutCard = makeCard()
        stack.addArrangedSubview(shortcutCard)
        shortcutCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let shortcutStack = makeCardStack()
        shortcutCard.addSubview(shortcutStack)
        pinCardStack(shortcutStack, to: shortcutCard)

        toggleHotkeyRecordButton = NSButton(title: "—", target: self, action: #selector(toggleHotkeyRecordTapped))
        styleHotkeyMainButton(toggleHotkeyRecordButton)
        toggleHotkeyClearButton = makeHotkeyClearAccessoryButton(action: #selector(toggleHotkeyClearTapped))
        shortcutStack.addArrangedSubview(
            makeHotkeyPreferenceRow(
                titleKey: "settings.hotkey.timer.title",
                subtitleKey: "settings.hotkey.timer.subtitle",
                subtitleDetailKey: "settings.hotkey.timer.detail",
                record: toggleHotkeyRecordButton,
                clear: toggleHotkeyClearButton
            )
        )
        shortcutStack.addArrangedSubview(cardDivider())

        restHotkeyRecordButton = NSButton(title: "—", target: self, action: #selector(restHotkeyRecordTapped))
        styleHotkeyMainButton(restHotkeyRecordButton)
        restHotkeyClearButton = makeHotkeyClearAccessoryButton(action: #selector(restHotkeyClearTapped))
        shortcutStack.addArrangedSubview(
            makeHotkeyPreferenceRow(
                titleKey: "settings.hotkey.restNow.title",
                subtitleKey: "settings.hotkey.restNow.subtitle",
                subtitleDetailKey: "settings.hotkey.restNow.detail",
                record: restHotkeyRecordButton,
                clear: restHotkeyClearButton
            )
        )

        for row in shortcutStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: shortcutStack.widthAnchor).isActive = true
        }

        stack.setCustomSpacing(16, after: shortcutCard)

        // ── TIMER ──────────────────────────────────
        stack.addArrangedSubview(sectionHeader("settings.section.timer"))

        let timerCard = makeCard()
        stack.addArrangedSubview(timerCard)
        timerCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let timerStack = makeCardStack()
        timerCard.addSubview(timerStack)
        pinCardStack(timerStack, to: timerCard)

        let (workRow, wField, wStepper) = makeDurationRow(labelKey: "settings.workDuration.label", unitKey: "settings.duration.min", min: 1, max: 120, action: #selector(workStepperChanged))
        workTextField = wField
        workStepper = wStepper
        timerStack.addArrangedSubview(workRow)
        workRow.widthAnchor.constraint(equalTo: timerStack.widthAnchor).isActive = true

        timerStack.addArrangedSubview(cardDivider())

        let (restRow, rField, rStepper) = makeDurationRow(labelKey: "settings.restDuration.label", unitKey: "settings.duration.min", min: 1, max: 30, action: #selector(restStepperChanged))
        restTextField = rField
        restStepper = rStepper
        timerStack.addArrangedSubview(restRow)
        restRow.widthAnchor.constraint(equalTo: timerStack.widthAnchor).isActive = true

        stack.setCustomSpacing(16, after: timerCard)

        // ── BEHAVIOR ───────────────────────────────
        stack.addArrangedSubview(sectionHeader("settings.section.behavior"))

        let behaviorCard = makeCard()
        stack.addArrangedSubview(behaviorCard)
        behaviorCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let behaviorStack = makeCardStack()
        behaviorCard.addSubview(behaviorStack)
        pinCardStack(behaviorStack, to: behaviorCard)

        enforceSwitch = NSSwitch()
        enforceSwitch.target = self
        enforceSwitch.action = #selector(enforceChanged)
        behaviorStack.addArrangedSubview(makeSwitchRow(labelKey: "settings.enforceRest.label", subtitleKey: "settings.enforceRest.subtitle", sw: enforceSwitch))
        behaviorStack.addArrangedSubview(cardDivider())

        restWindowAutoActivateSwitch = NSSwitch()
        restWindowAutoActivateSwitch.target = self
        restWindowAutoActivateSwitch.action = #selector(restWindowAutoActivateChanged)
        behaviorStack.addArrangedSubview(
            makeSwitchRow(
                labelKey: "settings.focusBreakWindow.label",
                subtitleKey: "settings.focusBreakWindow.subtitle",
                sw: restWindowAutoActivateSwitch
            )
        )
        behaviorStack.addArrangedSubview(cardDivider())

        waitForActivityAfterRestSwitch = NSSwitch()
        waitForActivityAfterRestSwitch.target = self
        waitForActivityAfterRestSwitch.action = #selector(waitForActivityAfterRestChanged)
        behaviorStack.addArrangedSubview(
            makeSwitchRow(
                labelKey: "settings.waitForActivity.label",
                subtitleKey: "settings.waitForActivity.subtitle",
                sw: waitForActivityAfterRestSwitch
            )
        )
        behaviorStack.addArrangedSubview(cardDivider())

        pauseOnLockSwitch = NSSwitch()
        pauseOnLockSwitch.target = self
        pauseOnLockSwitch.action = #selector(pauseOnLockChanged)
        behaviorStack.addArrangedSubview(makeSwitchRow(labelKey: "settings.pauseOnLock.label", subtitleKey: "settings.pauseOnLock.subtitle", sw: pauseOnLockSwitch))

        for row in behaviorStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: behaviorStack.widthAnchor).isActive = true
        }

        stack.setCustomSpacing(16, after: behaviorCard)

        // ── NOTIFICATIONS ──────────────────────────
        stack.addArrangedSubview(sectionHeader("settings.section.notifications"))

        let notifyCard = makeCard()
        stack.addArrangedSubview(notifyCard)
        notifyCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let notifyStack = makeCardStack()
        notifyCard.addSubview(notifyStack)
        pinCardStack(notifyStack, to: notifyCard)

        notifyWorkSwitch = NSSwitch()
        notifyWorkSwitch.target = self
        notifyWorkSwitch.action = #selector(notifyWorkChanged)
        notifyStack.addArrangedSubview(makeSwitchRow(labelKey: "settings.notifyWorkEnd.label", subtitleKey: "settings.notifyWorkEnd.subtitle", sw: notifyWorkSwitch))
        notifyStack.addArrangedSubview(cardDivider())

        notifyRestSwitch = NSSwitch()
        notifyRestSwitch.target = self
        notifyRestSwitch.action = #selector(notifyRestChanged)
        notifyStack.addArrangedSubview(makeSwitchRow(labelKey: "settings.notifyRestEnd.label", subtitleKey: "settings.notifyRestEnd.subtitle", sw: notifyRestSwitch))
        notifyStack.addArrangedSubview(cardDivider())

        soundSwitch = NSSwitch()
        soundSwitch.target = self
        soundSwitch.action = #selector(soundChanged)
        notifyStack.addArrangedSubview(makeSwitchRow(labelKey: "settings.sound.label", subtitleKey: "settings.sound.subtitle", sw: soundSwitch))

        for row in notifyStack.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: notifyStack.widthAnchor).isActive = true
        }

        stack.setCustomSpacing(16, after: notifyCard)

        loadSettings()
    }

    // MARK: - Card Builder Helpers

    private func makeCard() -> NSView {
        let card = ThemeAdaptiveView()
        card.lightColor = ThemeColor.cardBackground
        card.darkColor  = ThemeColor.cardBackground
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
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

    private func sectionHeader(_ key: String) -> EyeGuardSectionHeaderView {
        EyeGuardSectionHeaderView(titleKey: key)
    }

    private func cardDivider() -> NSView {
        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.separatorColor.cgColor
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return line
    }

    private func makeDurationRow(labelKey: String, unitKey: String, min: Int, max: Int, action: Selector)
        -> (NSView, NSTextField, NSStepper) {

        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let lbl = rowLabel(L10n.string(forKey: labelKey))
        lbl.identifier = NSUserInterfaceItemIdentifier(labelKey)
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

        let unitLbl = NSTextField(labelWithString: L10n.string(forKey: unitKey))
        unitLbl.identifier = NSUserInterfaceItemIdentifier(unitKey)
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

    private func makeSwitchRow(labelKey: String, subtitleKey: String, sw: NSSwitch) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let lbl = rowLabel(L10n.string(forKey: labelKey))
        lbl.identifier = NSUserInterfaceItemIdentifier(labelKey)
        row.addSubview(lbl)

        let sub = NSTextField(labelWithString: L10n.string(forKey: subtitleKey))
        sub.identifier = NSUserInterfaceItemIdentifier(subtitleKey)
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

    private func makePopupRow(labelKey: String, popup: NSPopUpButton) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let lbl = rowLabel(L10n.string(forKey: labelKey))
        lbl.identifier = NSUserInterfaceItemIdentifier(labelKey)
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

    private func makeSegmentRow(labelKey: String, segment: NSSegmentedControl) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let lbl = rowLabel(L10n.string(forKey: labelKey))
        lbl.identifier = NSUserInterfaceItemIdentifier(labelKey)
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

    /// 主快捷键按钮：无边框，置于组合框内左侧
    private func styleHotkeyMainButton(_ button: NSButton) {
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.setButtonType(.momentaryPushIn)
        button.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        button.alignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    /// 构建组合框右侧的 “×” 清除控件
    private func makeHotkeyClearAccessoryButton(action: Selector) -> NSButton {
        let clear = NSButton(title: "×", target: self, action: action)
        clear.isBordered = false
        clear.bezelStyle = .regularSquare
        clear.setButtonType(.momentaryPushIn)
        clear.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        clear.contentTintColor = .secondaryLabelColor
        clear.toolTip = L10n.hotkeyClearTooltip
        clear.focusRingType = .none
        clear.translatesAutoresizingMaskIntoConstraints = false
        clear.widthAnchor.constraint(equalToConstant: 24).isActive = true
        clear.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return clear
    }

    /// 快捷键行：标题 + 简短说明（过长省略，详情见 `subtitleDetail` 的 tooltip）+ 组合框
    private func makeHotkeyPreferenceRow(
        titleKey: String,
        subtitleKey: String,
        subtitleDetailKey: String,
        record: NSButton,
        clear: NSButton
    ) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let detail = L10n.string(forKey: subtitleDetailKey)
        let lbl = rowLabel(L10n.string(forKey: titleKey))
        lbl.identifier = NSUserInterfaceItemIdentifier(titleKey)
        let sub = NSTextField(labelWithString: L10n.string(forKey: subtitleKey))
        sub.identifier = NSUserInterfaceItemIdentifier(subtitleKey)
        sub.font = NSFont.systemFont(ofSize: 11)
        sub.textColor = .secondaryLabelColor
        sub.lineBreakMode = .byTruncatingTail
        sub.maximumNumberOfLines = 1
        sub.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sub.translatesAutoresizingMaskIntoConstraints = false
        sub.toolTip = detail
        lbl.toolTip = detail
        row.toolTip = detail

        let fieldBox = ShortcutFieldContainer()
        fieldBox.translatesAutoresizingMaskIntoConstraints = false

        let fillerLeading = NSView()
        fillerLeading.translatesAutoresizingMaskIntoConstraints = false
        let fillerTrailing = NSView()
        fillerTrailing.translatesAutoresizingMaskIntoConstraints = false
        fillerLeading.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fillerTrailing.setContentHuggingPriority(.defaultLow, for: .horizontal)

        record.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        record.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        let inner = NSStackView(views: [fillerLeading, record, fillerTrailing, clear])
        inner.orientation = .horizontal
        inner.alignment = .centerY
        inner.spacing = 0
        inner.edgeInsets = NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        inner.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.addSubview(inner)

        clear.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(lbl)
        row.addSubview(sub)
        row.addSubview(fieldBox)

        NSLayoutConstraint.activate([
            fillerLeading.widthAnchor.constraint(equalTo: fillerTrailing.widthAnchor),

            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),

            sub.leadingAnchor.constraint(equalTo: lbl.leadingAnchor),
            sub.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 2),
            sub.trailingAnchor.constraint(equalTo: fieldBox.leadingAnchor, constant: -12),

            fieldBox.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            fieldBox.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            fieldBox.widthAnchor.constraint(equalToConstant: 125),
            fieldBox.heightAnchor.constraint(equalToConstant: 28),

            inner.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor),
            inner.topAnchor.constraint(equalTo: fieldBox.topAnchor),
            inner.bottomAnchor.constraint(equalTo: fieldBox.bottomAnchor),
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
        case .classic:     return L10n.styleClassic
        case .minimal:     return L10n.styleMinimal
        case .emoji:       return L10n.styleEmoji
        case .compact:     return L10n.styleCompact
        case .bracket:     return L10n.styleBracket
        case .star:        return L10n.styleStar
        case .dots:        return L10n.styleDots
        case .progressBar: return L10n.styleProgressBar
        }
    }

    private func languagePopupTitles() -> [String] {
        [L10n.languageSystem, L10n.languageEnglish, L10n.languageChinese]
    }

    private func reloadLanguagePopupItems() {
        let selected = languagePopup.indexOfSelectedItem
        languagePopup.removeAllItems()
        languagePopup.addItems(withTitles: languagePopupTitles())
        if selected >= 0, selected < languagePopup.numberOfItems {
            languagePopup.selectItem(at: selected)
        }
    }

    private func reloadStylePopupItems() {
        let selected = statusBarStylePopup.indexOfSelectedItem
        statusBarStylePopup.removeAllItems()
        statusBarStylePopup.addItems(withTitles: Settings.StatusBarStyle.allCases.map { styleDisplayName($0) })
        if selected >= 0, selected < statusBarStylePopup.numberOfItems {
            statusBarStylePopup.selectItem(at: selected)
        }
    }

    private func reloadPositionPopupItems() {
        let selected = restWindowPositionPopup.indexOfSelectedItem
        restWindowPositionPopup.removeAllItems()
        restWindowPositionPopup.addItems(withTitles: [L10n.positionCenter, L10n.positionTopRight])
        if selected >= 0, selected < restWindowPositionPopup.numberOfItems {
            restWindowPositionPopup.selectItem(at: selected)
        }
    }

    /// 遍历设置窗控件树，按 `identifier` 刷新本地化文案。
    private func localizeViewTree(_ view: NSView?) {
        guard let view else { return }
        if let key = view.identifier?.rawValue, !key.isEmpty,
           let field = view as? NSTextField {
            field.stringValue = L10n.string(forKey: key)
        }
        for sub in view.subviews {
            localizeViewTree(sub)
        }
    }

    /// 语言切换后刷新设置界面文案（窗口已构建时调用）。
    /// 刷新设置页顶栏：「标题 · 描述」同一行。
    private func updateSettingsHeader() {
        let title = L10n.settingsTitle
        let subtitle = L10n.settingsSubtitle
        let separator = " · "
        let full = title + separator + subtitle
        let attr = NSMutableAttributedString(string: full)

        let titleRange = (full as NSString).range(of: title)
        let sepRange = (full as NSString).range(of: separator)
        let subRange = (full as NSString).range(of: subtitle)

        attr.addAttributes([
            .font: NSFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: NSColor.labelColor,
        ], range: titleRange)
        attr.addAttributes([
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ], range: sepRange)
        attr.addAttributes([
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.secondaryLabelColor,
        ], range: subRange)

        settingsHeaderLabel?.attributedStringValue = attr
    }

    func applyLocalization() {
        window.title = L10n.settingsTitle
        updateSettingsHeader()
        localizeViewTree(window.contentView)
        themeSegment.setLabel(L10n.themeSystem, forSegment: 0)
        themeSegment.setLabel(L10n.themeLight, forSegment: 1)
        themeSegment.setLabel(L10n.themeDark, forSegment: 2)
        reloadLanguagePopupItems()
        reloadStylePopupItems()
        reloadPositionPopupItems()
        toggleHotkeyClearButton.toolTip = L10n.hotkeyClearTooltip
        restHotkeyClearButton.toolTip = L10n.hotkeyClearTooltip
        refreshHotkeyButtons()
        loadSettings()
    }

    // MARK: - Load Settings

    private func loadSettings() {
        let s = Settings.shared
        workTextField.integerValue = s.workDuration / 60
        workStepper.integerValue   = s.workDuration / 60
        restTextField.integerValue = s.restDuration / 60
        restStepper.integerValue   = s.restDuration / 60

        enforceSwitch.state               = s.enforceRest               ? .on : .off
        restWindowAutoActivateSwitch.state = s.restWindowAutoActivate   ? .on : .off
        waitForActivityAfterRestSwitch.state = s.waitForActivityAfterRest ? .on : .off
        pauseOnLockSwitch.state           = s.pauseOnLock               ? .on : .off
        notifyWorkSwitch.state   = s.notifyOnWorkEnd  ? .on : .off
        notifyRestSwitch.state   = s.notifyOnRestEnd  ? .on : .off
        soundSwitch.state        = s.soundEnabled     ? .on : .off
        loginSwitch.state        = LoginItemManager.shared.isEnabled ? .on : .off
        statusBarStylePopup.selectItem(at: s.statusBarStyle.index)
        restWindowPositionPopup.selectItem(at: s.restWindowPosition.index)
        themeSegment.selectedSegment = s.themeMode.index
        languagePopup.selectItem(at: s.appLanguage.index)
        refreshHotkeyButtons()
    }

    /// 根据 `Settings` 与是否正在录制，刷新快捷键按钮标题
    private func refreshHotkeyButtons() {
        let s = Settings.shared
        if hotkeyRecordingSlot == .toggle {
            toggleHotkeyRecordButton.title = L10n.hotkeyPressKeys
        } else if s.isGlobalHotkeyToggleEnabled {
            toggleHotkeyRecordButton.title = HotkeyDisplayFormatter.displayString(
                keyCode: s.globalHotkeyToggleKeyCode,
                carbonModifiers: s.globalHotkeyToggleCarbonModifiers
            )
        } else {
            toggleHotkeyRecordButton.title = L10n.hotkeyClickToSet
        }

        if hotkeyRecordingSlot == .restNow {
            restHotkeyRecordButton.title = L10n.hotkeyPressKeys
        } else if s.isGlobalHotkeyRestNowEnabled {
            restHotkeyRecordButton.title = HotkeyDisplayFormatter.displayString(
                keyCode: s.globalHotkeyRestNowKeyCode,
                carbonModifiers: s.globalHotkeyRestNowCarbonModifiers
            )
        } else {
            restHotkeyRecordButton.title = L10n.hotkeyClickToSet
        }

        let showToggleClear = s.isGlobalHotkeyToggleEnabled || hotkeyRecordingSlot == .toggle
        toggleHotkeyClearButton.isHidden = !showToggleClear
        let showRestClear = s.isGlobalHotkeyRestNowEnabled || hotkeyRecordingSlot == .restNow
        restHotkeyClearButton.isHidden = !showRestClear
    }

    /// 进入指定槽位的快捷键录制（再次点击同一按钮可取消）
    private func beginHotkeyRecording(_ slot: HotkeyRecordingSlot) {
        if hotkeyRecordingSlot == slot {
            hotkeyRecordingSlot = nil
        } else {
            hotkeyRecordingSlot = slot
        }
        refreshHotkeyButtons()
    }

    /// 取消正在进行的录制
    private func cancelHotkeyRecording() {
        hotkeyRecordingSlot = nil
        refreshHotkeyButtons()
    }

    /// 将录制到的组合写入设置并重新注册全局热键
    private func applyHotkeyRecording(slot: HotkeyRecordingSlot, keyCode: UInt32, modifiers: UInt32) {
        let settings = Settings.shared
        switch slot {
        case .toggle:
            if settings.globalHotkeyConflicts(isToggle: true, keyCode: keyCode, carbonModifiers: modifiers) {
                settings.clearGlobalHotkeyRestNow()
            }
            settings.setGlobalHotkeyToggle(keyCode: keyCode, carbonModifiers: modifiers)
        case .restNow:
            if settings.globalHotkeyConflicts(isToggle: false, keyCode: keyCode, carbonModifiers: modifiers) {
                settings.clearGlobalHotkeyToggle()
            }
            settings.setGlobalHotkeyRestNow(keyCode: keyCode, carbonModifiers: modifiers)
        }
        hotkeyRecordingSlot = nil
        refreshHotkeyButtons()
        NotificationCenter.default.post(name: .settingsDidChange, object: "globalHotkeys")
    }

    @objc private func toggleHotkeyRecordTapped() {
        beginHotkeyRecording(.toggle)
    }

    @objc private func restHotkeyRecordTapped() {
        beginHotkeyRecording(.restNow)
    }

    @objc private func toggleHotkeyClearTapped() {
        if hotkeyRecordingSlot == .toggle {
            cancelHotkeyRecording()
            return
        }
        Settings.shared.clearGlobalHotkeyToggle()
        refreshHotkeyButtons()
        NotificationCenter.default.post(name: .settingsDidChange, object: "globalHotkeys")
    }

    @objc private func restHotkeyClearTapped() {
        if hotkeyRecordingSlot == .restNow {
            cancelHotkeyRecording()
            return
        }
        Settings.shared.clearGlobalHotkeyRestNow()
        refreshHotkeyButtons()
        NotificationCenter.default.post(name: .settingsDidChange, object: "globalHotkeys")
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

    /// 同步「休息弹窗是否自动获取焦点」到持久化存储。
    @objc private func restWindowAutoActivateChanged() {
        Settings.shared.restWindowAutoActivate = (restWindowAutoActivateSwitch.state == .on)
    }

    /// 同步「休息结束后等待活动再开工」到持久化存储。
    @objc private func waitForActivityAfterRestChanged() {
        Settings.shared.waitForActivityAfterRest = (waitForActivityAfterRestSwitch.state == .on)
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

    @objc private func languageChanged() {
        let lang = Settings.AppLanguage.allCases[languagePopup.indexOfSelectedItem]
        guard Settings.shared.appLanguage != lang else { return }
        Settings.shared.appLanguage = lang
        NotificationCenter.default.post(name: .settingsDidChange, object: "appLanguage")
    }

    // MARK: - Show / NSWindowDelegate

    func show() {
        applyLocalization()
        loadSettings()
        updateTitleBarInsets()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func windowDidResize(_ notification: Notification) {
        updateTitleBarInsets()
    }

    /// 根据标题栏高度调整主标题顶部间距。
    private func updateTitleBarInsets() {
        titleTopConstraint?.constant = EyeGuardWindowChrome.titleTopInset(for: window)
    }

    func windowWillClose(_ notification: Notification) {
        cancelHotkeyRecording()
        removeKeyMonitor()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if let slot = self.hotkeyRecordingSlot {
                return self.handleHotkeyKeyDown(event, recording: slot)
            }
            guard event.modifierFlags.contains(.command) else { return event }
            switch event.keyCode {
            case 13: self.window.close(); return nil
            case 12: NSApp.terminate(nil); return nil
            default: return event
            }
        }
    }

    /// 录制模式下处理按键：`Esc` 取消；必须含 ⌘ 或 ⌃
    private func handleHotkeyKeyDown(_ event: NSEvent, recording slot: HotkeyRecordingSlot) -> NSEvent? {
        if event.keyCode == 53 {
            cancelHotkeyRecording()
            return nil
        }
        guard event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) else {
            NSSound.beep()
            return nil
        }
        let mods = event.modifierFlags.carbonModifierMask
        let keyCode = UInt32(event.keyCode)
        applyHotkeyRecording(slot: slot, keyCode: keyCode, modifiers: mods)
        return nil
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

// MARK: - Shortcut combo field (styled container)

/// 快捷键组合框视觉容器：圆角、分隔边框、随外观变化的背景
private final class ShortcutFieldContainer: NSView {

    override var wantsUpdateLayer: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayer() {
        guard let layer = layer else { return }
        layer.cornerRadius = 6
        layer.borderWidth = 1
        var bg = NSColor.controlBackgroundColor
        var border = NSColor.separatorColor
        effectiveAppearance.performAsCurrentDrawingAppearance {
            bg = NSColor.controlBackgroundColor
            border = NSColor.separatorColor
        }
        layer.backgroundColor = bg.cgColor
        layer.borderColor = border.cgColor
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
