import AppKit

/// 状态栏菜单控制器
class StatusBarController: NSObject {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    weak var timerManager: TimerManager?

    // 菜单项
    private var statusMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var restNowMenuItem: NSMenuItem!
    private var styleSubmenuItem: NSMenuItem!

    // MARK: - Init

    override init() {
        super.init()
        setupStatusItem()
        setupMenu()
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    @objc private func settingsDidChange() {
        guard let manager = timerManager else { return }
        updateState(manager.state, remaining: manager.remainingSeconds)
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = nil
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupMenu() {
        menu = NSMenu()

        // 状态行
        statusMenuItem = NSMenuItem(title: "当前状态: 空闲", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Toggle（暂停/继续）
        toggleMenuItem = NSMenuItem(title: L10n.menuStart, action: #selector(toggleClicked), keyEquivalent: "")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        // 立即休息
        restNowMenuItem = NSMenuItem(title: L10n.menuRestNow, action: #selector(restNowClicked), keyEquivalent: "")
        restNowMenuItem.target = self
        menu.addItem(restNowMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 屏幕亮度
        let dimItem = NSMenuItem(title: L10n.menuDimScreen, action: #selector(dimScreenClicked), keyEquivalent: "")
        dimItem.target = self
        menu.addItem(dimItem)

        let brightItem = NSMenuItem(title: L10n.menuBrightScreen, action: #selector(brightScreenClicked), keyEquivalent: "")
        brightItem.target = self
        menu.addItem(brightItem)

        menu.addItem(NSMenuItem.separator())

        // 状态栏皮肤
        styleSubmenuItem = NSMenuItem(title: L10n.statusBarStyle, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for style in Settings.StatusBarStyle.allCases {
            let item = NSMenuItem(title: styleDisplayName(style), action: #selector(styleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = style.index
            if style == Settings.shared.statusBarStyle {
                item.state = .on
            }
            submenu.addItem(item)
        }
        styleSubmenuItem.submenu = submenu
        menu.addItem(styleSubmenuItem)

        updateStyleSubmenuPreviews()

        menu.addItem(NSMenuItem.separator())

        // 今日统计
        let statsItem = NSMenuItem(title: L10n.todayStats, action: nil, keyEquivalent: "")
        statsItem.isEnabled = false
        menu.addItem(statsItem)

        let roundsItem = NSMenuItem(title: L10n.roundsCompleted(StatsManager.shared.roundsCompletedToday), action: nil, keyEquivalent: "")
        roundsItem.isEnabled = false
        menu.addItem(roundsItem)

        let restItem = NSMenuItem(title: L10n.totalRest(StatsManager.shared.totalRestMinutesToday), action: nil, keyEquivalent: "")
        restItem.isEnabled = false
        menu.addItem(restItem)

        menu.addItem(NSMenuItem.separator())

        // 设置
        let settingsItem = NSMenuItem(title: L10n.menuSettings, action: #selector(settingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: L10n.menuAbout, action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(title: L10n.menuQuit, action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    @objc private func toggleClicked() {
        guard let manager = timerManager else { return }
        switch manager.state {
        case .idle:
            manager.start()
        case .working:
            manager.pause()
        case .paused:
            manager.resume()
        case .resting:
            break // 休息中不可操作
        }
    }

    @objc private func restNowClicked() {
        timerManager?.restNow()
    }

    @objc private func dimScreenClicked() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Users/lilou/.hermes/bin/set_brightness")
        task.arguments = ["0.0"]
        try? task.run()
    }

    @objc private func brightScreenClicked() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Users/lilou/.hermes/bin/set_brightness")
        task.arguments = ["0.8"]
        try? task.run()
    }

    @objc private func styleSelected(_ sender: NSMenuItem) {
        let style = Settings.StatusBarStyle.allCases[sender.tag]
        Settings.shared.statusBarStyle = style
        updateStyleSubmenuCheckmark()
        updateStyleSubmenuPreviews()
        NotificationCenter.default.post(name: .settingsDidChange, object: "statusBarStyle")
    }

    private func updateStyleSubmenuCheckmark() {
        guard let submenu = styleSubmenuItem.submenu else { return }
        let current = Settings.shared.statusBarStyle
        for item in submenu.items {
            item.state = (Settings.StatusBarStyle.allCases[item.tag] == current) ? .on : .off
        }
    }

    /// 更新子菜单中每个样式的预览文字
    private func updateStyleSubmenuPreviews() {
        guard let submenu = styleSubmenuItem.submenu else { return }
        for item in submenu.items {
            let style = Settings.StatusBarStyle.allCases[item.tag]
            let preview = previewText(for: style)
            let displayName = styleDisplayName(style)
            let attributedTitle = buildMenuItemTitle(name: displayName, preview: preview)
            item.attributedTitle = attributedTitle
        }
        print("[EyeGuard] updateStyleSubmenuPreviews called, item count: \(submenu.items.count)")
        if let first = submenu.items.first {
            print("[EyeGuard] first item title: \(first.title), attributedTitle: \(first.attributedTitle?.string ?? "nil")")
        }
    }

    /// 构建带预览的菜单项标题
    private func buildMenuItemTitle(name: String, preview: String) -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: 13)
        let grayColor = NSColor(white: 0.5, alpha: 1.0)

        let namePart = NSMutableAttributedString(string: name, attributes: [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ])

        let previewPart = NSMutableAttributedString(string: "  " + preview, attributes: [
            .font: font,
            .foregroundColor: grayColor
        ])

        let result = NSMutableAttributedString()
        result.append(namePart)
        result.append(previewPart)
        return result
    }

    /// 生成指定样式的预览文字（工作中状态，30:00）
    private func previewText(for style: Settings.StatusBarStyle) -> String {
        let timeStr = "30:00"
        switch style {
        case .classic:
            return "\"Working 30:00\""
        case .minimal:
            return "\"30:00\""
        case .emoji:
            return "\"💼 30:00\""
        case .compact:
            return "\"W 30:00\""
        case .bracket:
            return "\"[工作中] 30:00\""
        case .star:
            return "\"☆工作中☆ 30:00\""
        case .dots:
            return "\"◐ 30:00\""
        case .progressBar:
            return "\"████████ 30:00\""
        }
    }

    @objc private func settingsClicked() {
        SettingsWindowController.shared.show()
    }

    @objc private func aboutClicked() {
        NotificationCenter.default.post(name: .showAboutWindow, object: nil)
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }

    // MARK: - Update UI

    func updateState(_ state: EyeState, remaining: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshMenu(state: state, remaining: remaining)
        }
    }

    private func refreshMenu(state: EyeState, remaining: Int) {
        // 状态文字
        let timeStr = formatTime(remaining)
        switch state {
        case .idle:
            statusMenuItem.title = L10n.statusIdle
            toggleMenuItem.title = L10n.menuStart
            toggleMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = false
            applyStatusBarTitle(L10n.appName, state: .idle)

        case .working:
            statusMenuItem.title = L10n.statusWorking(timeStr)
            toggleMenuItem.title = L10n.menuPause
            toggleMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = true
            applyStatusBarTitle(formatStatusBarText(state: .working, timeStr: timeStr, remaining: remaining), state: .working)

        case .paused(let frozen):
            statusMenuItem.title = L10n.statusPaused(formatTime(frozen))
            toggleMenuItem.title = L10n.menuResume
            toggleMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = true
            applyStatusBarTitle(formatStatusBarText(state: .paused(remaining: frozen), timeStr: formatTime(frozen), remaining: frozen), state: .paused(remaining: frozen))

        case .resting:
            statusMenuItem.title = L10n.statusResting(timeStr)
            toggleMenuItem.isEnabled = false
            restNowMenuItem.isEnabled = false
            applyStatusBarTitle(formatStatusBarText(state: .resting, timeStr: timeStr, remaining: remaining), state: .resting)
        }
    }

    private func formatStatusBarText(state: EyeState, timeStr: String, remaining: Int) -> String {
        let style = Settings.shared.statusBarStyle
        switch style {
        case .classic:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "Working \(timeStr)"
            case .paused:  return "Paused \(timeStr)"
            case .resting: return "Resting \(timeStr)"
            }
        case .minimal:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "\(timeStr)"
            case .paused:  return "\(timeStr)"
            case .resting: return "\(timeStr)"
            }
        case .emoji:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "💼 \(timeStr)"
            case .paused:  return "⏸ \(timeStr)"
            case .resting: return "🌿 \(timeStr)"
            }
        case .compact:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "W \(timeStr)"
            case .paused:  return "P \(timeStr)"
            case .resting: return "R \(timeStr)"
            }
        case .bracket:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "[工作中] \(timeStr)"
            case .paused:  return "[已暂停] \(timeStr)"
            case .resting: return "[休息中] \(timeStr)"
            }
        case .star:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "☆工作中☆ \(timeStr)"
            case .paused:  return "☆已暂停☆ \(timeStr)"
            case .resting: return "☆休息中☆ \(timeStr)"
            }
        case .dots:
            // 进度点：◐◔◑◕ 动态圆弧表示进度
            let total = totalSeconds(for: state)
            let filled = total > 0 ? (total - remaining) * 4 / total : 0
            let dots = ["◐", "◔", "◑", "◕"]
            switch state {
            case .idle:    return L10n.appName
            case .working: return "\(dots[min(filled, 3)]) \(timeStr)"
            case .paused:  return "⏸ \(timeStr)"
            case .resting: return "\(dots[min(filled, 3)]) \(timeStr)"
            }
        case .progressBar:
            // 进度条：███░░░░░ 表示进度
            let total = totalSeconds(for: state)
            let barLength = 8
            let filled = total > 0 ? (total - remaining) * barLength / total : 0
            let bar = String(repeating: "█", count: min(filled, barLength)) + String(repeating: "░", count: barLength - min(filled, barLength))
            switch state {
            case .idle:    return L10n.appName
            case .working: return "\(bar) \(timeStr)"
            case .paused:  return "⏸ \(timeStr)"
            case .resting: return "\(bar) \(timeStr)"
            }
        }
    }

    /// 根据状态获取状态栏文字颜色
    private func statusBarColor(for state: EyeState) -> NSColor {
        switch state {
        case .idle, .working:
            return .labelColor
        case .paused:
            return .systemYellow
        case .resting:
            return .systemGreen
        }
    }

    /// 设置状态栏按钮的着色文字
    private func applyStatusBarTitle(_ title: String, state: EyeState) {
        guard let button = statusItem.button else { return }
        button.image = nil
        let color = statusBarColor(for: state)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: font
        ]
        button.attributedTitle = NSAttributedString(string: title, attributes: attrs)
    }

    /// 根据状态获取总时长（秒）
    private func totalSeconds(for state: EyeState) -> Int {
        switch state {
        case .idle:    return 0
        case .working: return Settings.shared.workDuration
        case .paused:  return Settings.shared.workDuration  // 暂停时用工作总时长算进度
        case .resting: return Settings.shared.restDuration
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
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
}

// MARK: - TimerManager 用到的计算属性

extension TimerManager {
    var currentState: EyeState {
        return state
    }
}
