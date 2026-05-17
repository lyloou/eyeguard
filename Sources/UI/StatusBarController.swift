import AppKit

/// 状态栏菜单控制器
class StatusBarController: NSObject {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    weak var timerManager: TimerManager?

    // 菜单项
    private var menuHeaderView: StatusMenuHeaderView!
    private var toggleMenuItem: NSMenuItem!
    private var restNowMenuItem: NSMenuItem!
    private var dimMenuItem: NSMenuItem!
    private var brightMenuItem: NSMenuItem!
    private var styleSubmenuItem: NSMenuItem!
    private var statsMenuItem: NSMenuItem!
    private var workStatsMenuItem: NSMenuItem!
    private var roundsMenuItem: NSMenuItem!
    private var restStatsMenuItem: NSMenuItem!
    private var viewStatsMenuItem: NSMenuItem!
    private var settingsMenuItem: NSMenuItem!
    private var aboutMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!

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

    @objc private func settingsDidChange(_ notification: Notification) {
        guard let manager = timerManager else { return }
        if let key = notification.object as? String, key == "appLanguage" {
            refreshLocalizedUI()
            return
        }
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
        StatusMenuStyle.apply(to: menu)

        menuHeaderView = StatusMenuHeaderView(frame: .zero)
        let headerItem = NSMenuItem()
        headerItem.view = menuHeaderView
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        StatusMenuStyle.addSection(L10n.menuSectionControl, to: menu)

        toggleMenuItem = StatusMenuStyle.item(
            title: L10n.menuStart,
            symbol: "play.fill",
            action: #selector(toggleClicked),
            target: self
        )
        menu.addItem(toggleMenuItem)

        restNowMenuItem = StatusMenuStyle.item(
            title: L10n.menuRestNow,
            symbol: "cup.and.saucer.fill",
            action: #selector(restNowClicked),
            target: self
        )
        menu.addItem(restNowMenuItem)

        menu.addItem(NSMenuItem.separator())

        StatusMenuStyle.addSection(L10n.menuSectionDisplay, to: menu)

        styleSubmenuItem = StatusMenuStyle.item(
            title: L10n.statusBarStyle,
            symbol: "textformat",
            action: nil,
            target: nil
        )
        let styleMenu = NSMenu()
        StatusMenuStyle.apply(to: styleMenu)
        for style in Settings.StatusBarStyle.allCases {
            let item = NSMenuItem(title: styleDisplayName(style), action: #selector(styleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = style.index
            if style == Settings.shared.statusBarStyle {
                item.state = .on
            }
            styleMenu.addItem(item)
        }
        styleSubmenuItem.submenu = styleMenu
        menu.addItem(styleSubmenuItem)
        updateStyleSubmenuPreviews()

        dimMenuItem = StatusMenuStyle.item(
            title: L10n.menuDimScreen,
            symbol: "moon.fill",
            action: #selector(dimScreenClicked),
            target: self
        )
        menu.addItem(dimMenuItem)

        brightMenuItem = StatusMenuStyle.item(
            title: L10n.menuBrightScreen,
            symbol: "sun.max.fill",
            action: #selector(brightScreenClicked),
            target: self
        )
        menu.addItem(brightMenuItem)

        menu.addItem(NSMenuItem.separator())

        StatusMenuStyle.addSection(L10n.menuSectionStats, to: menu)

        statsMenuItem = NSMenuItem(title: L10n.todayStats, action: nil, keyEquivalent: "")
        statsMenuItem.isEnabled = false
        menu.addItem(statsMenuItem)

        workStatsMenuItem = statLineItem(
            title: L10n.totalWork(StatsManager.shared.totalWorkMinutesToday),
            symbol: "clock.fill"
        )
        menu.addItem(workStatsMenuItem)

        restStatsMenuItem = statLineItem(
            title: L10n.totalRest(StatsManager.shared.totalRestMinutesToday),
            symbol: "leaf.fill"
        )
        menu.addItem(restStatsMenuItem)

        roundsMenuItem = statLineItem(
            title: L10n.roundsCompleted(StatsManager.shared.roundsCompletedToday),
            symbol: "arrow.triangle.2.circlepath"
        )
        menu.addItem(roundsMenuItem)

        viewStatsMenuItem = StatusMenuStyle.item(
            title: L10n.menuViewStats,
            symbol: "chart.xyaxis.line",
            action: #selector(viewStatsClicked),
            target: self
        )
        menu.addItem(viewStatsMenuItem)

        menu.addItem(NSMenuItem.separator())

        StatusMenuStyle.addSection(L10n.menuSectionApp, to: menu)

        settingsMenuItem = StatusMenuStyle.item(
            title: L10n.menuSettings,
            symbol: "gearshape.fill",
            action: #selector(settingsClicked),
            target: self,
            keyEquivalent: ","
        )
        menu.addItem(settingsMenuItem)

        aboutMenuItem = StatusMenuStyle.item(
            title: L10n.menuAbout,
            symbol: "info.circle.fill",
            action: #selector(aboutClicked),
            target: self
        )
        menu.addItem(aboutMenuItem)

        quitMenuItem = StatusMenuStyle.item(
            title: L10n.menuQuit,
            symbol: "power",
            action: #selector(quitClicked),
            target: self,
            keyEquivalent: "q"
        )
        menu.addItem(quitMenuItem)

        statusItem.menu = menu
    }

    /// 创建不可点击的统计行（带图标）。
    private func statLineItem(title: String, symbol: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            item.image = image.withSymbolConfiguration(config)
        }
        return item
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
        case .resting, .awaitingActivity:
            break
        }
    }

    @objc private func restNowClicked() {
        timerManager?.restNow()
    }

    @objc private func dimScreenClicked() {
        BrightnessManager.shared.dim()
    }

    @objc private func brightScreenClicked() {
        BrightnessManager.shared.bright()
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
        case .classic:     return L10n.previewClassic(timeStr)
        case .minimal:     return L10n.previewMinimal(timeStr)
        case .emoji:       return L10n.previewEmoji(timeStr)
        case .compact:     return L10n.previewCompact(timeStr)
        case .bracket:     return L10n.previewBracket(timeStr)
        case .star:        return L10n.previewStar(timeStr)
        case .dots:        return L10n.previewDots(timeStr)
        case .progressBar: return L10n.previewProgressBar(timeStr)
        }
    }

    @objc private func settingsClicked() {
        SettingsWindowController.shared.show()
    }

    @objc private func aboutClicked() {
        NotificationCenter.default.post(name: .showAboutWindow, object: nil)
    }

    @objc private func viewStatsClicked() {
        NotificationCenter.default.post(name: .showStatsWindow, object: nil)
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

    /// 语言切换后按当前状态重绘菜单与状态栏。
    func refreshLocalizedUI() {
        guard let manager = timerManager else { return }
        DispatchQueue.main.async { [weak self] in
            self?.rebuildMenuLocalizedStrings()
            self?.refreshMenu(state: manager.state, remaining: manager.remainingSeconds)
        }
    }

    /// 更新菜单中依赖本地化的静态标题（语言切换或统计刷新时调用）。
    private func rebuildMenuLocalizedStrings() {
        restNowMenuItem.title = L10n.menuRestNow
        dimMenuItem.title = L10n.menuDimScreen
        brightMenuItem.title = L10n.menuBrightScreen
        styleSubmenuItem.title = L10n.statusBarStyle

        if let submenu = styleSubmenuItem.submenu {
            for item in submenu.items {
                guard item.tag < Settings.StatusBarStyle.allCases.count else { continue }
                let style = Settings.StatusBarStyle.allCases[item.tag]
                item.title = styleDisplayName(style)
            }
        }
        updateStyleSubmenuPreviews()

        statsMenuItem.title = L10n.todayStats
        workStatsMenuItem.title = L10n.totalWork(StatsManager.shared.totalWorkMinutesToday)
        roundsMenuItem.title = L10n.roundsCompleted(StatsManager.shared.roundsCompletedToday)
        restStatsMenuItem.title = L10n.totalRest(StatsManager.shared.totalRestMinutesToday)
        viewStatsMenuItem.title = L10n.menuViewStats

        settingsMenuItem.title = L10n.menuSettings
        aboutMenuItem.title = L10n.menuAbout
        quitMenuItem.title = L10n.menuQuit
    }

    private func refreshMenu(state: EyeState, remaining: Int) {
        let timeStr = formatTime(remaining)
        switch state {
        case .idle:
            menuHeaderView.update(state: state, statusText: L10n.statusIdle, timeText: nil)
            toggleMenuItem.title = L10n.menuStart
            toggleMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = false
            applyStatusBarTitle(L10n.appName, state: .idle)

        case .working:
            menuHeaderView.update(state: state, statusText: L10n.statusWorking(timeStr), timeText: timeStr)
            toggleMenuItem.title = L10n.menuPause
            toggleMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = true
            applyStatusBarTitle(formatStatusBarText(state: .working, timeStr: timeStr, remaining: remaining), state: .working)

        case .paused(let frozen):
            let pausedTime = formatTime(frozen)
            menuHeaderView.update(state: state, statusText: L10n.statusPaused(pausedTime), timeText: pausedTime)
            toggleMenuItem.title = L10n.menuResume
            toggleMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = true
            applyStatusBarTitle(formatStatusBarText(state: .paused(remaining: frozen), timeStr: pausedTime, remaining: frozen), state: .paused(remaining: frozen))

        case .resting:
            menuHeaderView.update(state: state, statusText: L10n.statusResting(timeStr), timeText: timeStr)
            toggleMenuItem.isEnabled = false
            restNowMenuItem.isEnabled = false
            applyStatusBarTitle(formatStatusBarText(state: .resting, timeStr: timeStr, remaining: remaining), state: .resting)

        case .awaitingActivity:
            menuHeaderView.update(state: state, statusText: L10n.statusAwaitingActivity, timeText: nil)
            toggleMenuItem.isEnabled = false
            restNowMenuItem.isEnabled = false
            applyStatusBarTitle(formatStatusBarText(state: .awaitingActivity, timeStr: timeStr, remaining: remaining), state: .awaitingActivity)
        }

        workStatsMenuItem.title = L10n.totalWork(StatsManager.shared.totalWorkMinutesToday)
        roundsMenuItem.title = L10n.roundsCompleted(StatsManager.shared.roundsCompletedToday)
        restStatsMenuItem.title = L10n.totalRest(StatsManager.shared.totalRestMinutesToday)
    }

    private func formatStatusBarText(state: EyeState, timeStr: String, remaining: Int) -> String {
        let style = Settings.shared.statusBarStyle
        switch style {
        case .classic:
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarClassicWorking(timeStr)
            case .paused:  return L10n.statusBarClassicPaused(timeStr)
            case .resting: return L10n.statusBarClassicResting(timeStr)
            case .awaitingActivity: return L10n.statusBarAwaitingActivity
            }
        case .minimal:
            switch state {
            case .idle:    return L10n.appName
            case .working, .paused, .resting: return timeStr
            case .awaitingActivity: return L10n.statusBarAwaitingActivity
            }
        case .emoji:
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarEmojiWorking(timeStr)
            case .paused:  return L10n.statusBarEmojiPaused(timeStr)
            case .resting: return L10n.statusBarEmojiResting(timeStr)
            case .awaitingActivity: return L10n.statusBarEmojiAwaiting(timeStr)
            }
        case .compact:
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarCompactWorking(timeStr)
            case .paused:  return L10n.statusBarCompactPaused(timeStr)
            case .resting: return L10n.statusBarCompactResting(timeStr)
            case .awaitingActivity: return L10n.statusBarCompactAwaiting
            }
        case .bracket:
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarBracketWorking(timeStr)
            case .paused:  return L10n.statusBarBracketPaused(timeStr)
            case .resting: return L10n.statusBarBracketResting(timeStr)
            case .awaitingActivity: return L10n.statusBarBracketAwaiting
            }
        case .star:
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarStarWorking(timeStr)
            case .paused:  return L10n.statusBarStarPaused(timeStr)
            case .resting: return L10n.statusBarStarResting(timeStr)
            case .awaitingActivity: return L10n.statusBarStarAwaiting
            }
        case .dots:
            let total = totalSeconds(for: state)
            let filled = total > 0 ? (total - remaining) * 4 / total : 0
            let dots = ["◐", "◔", "◑", "◕"]
            let dot = dots[min(filled, 3)]
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarDotsWorking(dot, timeStr)
            case .paused:  return L10n.statusBarDotsPaused(timeStr)
            case .resting: return L10n.statusBarDotsResting(dot, timeStr)
            case .awaitingActivity: return L10n.statusBarDotsAwaiting
            }
        case .progressBar:
            let total = totalSeconds(for: state)
            let barLength = 8
            let filled = total > 0 ? (total - remaining) * barLength / total : 0
            let bar = String(repeating: "█", count: min(filled, barLength))
                + String(repeating: "░", count: barLength - min(filled, barLength))
            switch state {
            case .idle:    return L10n.appName
            case .working: return L10n.statusBarProgressWorking(bar, timeStr)
            case .paused:  return L10n.statusBarProgressPaused(timeStr)
            case .resting: return L10n.statusBarProgressResting(bar, timeStr)
            case .awaitingActivity: return L10n.statusBarProgressAwaiting
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
        case .awaitingActivity:
            return .systemTeal
        }
    }

    /// 设置状态栏按钮的着色文字
    private func applyStatusBarTitle(_ title: String, state: EyeState) {
        guard let button = statusItem.button else { return }
        button.image = nil
        let color = statusBarColor(for: state)
        let weight: NSFont.Weight
        switch state {
        case .working: weight = .semibold
        case .resting, .awaitingActivity: weight = .medium
        default:       weight = .regular
        }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: weight)
        let kern: CGFloat = state == .idle ? 0.3 : 0
        var attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: font
        ]
        if kern > 0 { attrs[.kern] = kern }
        button.attributedTitle = NSAttributedString(string: title, attributes: attrs)
    }

    /// 根据状态获取总时长（秒）
    private func totalSeconds(for state: EyeState) -> Int {
        switch state {
        case .idle:    return 0
        case .working: return Settings.shared.workDuration
        case .paused:  return Settings.shared.workDuration  // 暂停时用工作总时长算进度
        case .resting: return Settings.shared.restDuration
        case .awaitingActivity: return Settings.shared.workDuration
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
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
}

// MARK: - TimerManager 用到的计算属性

extension TimerManager {
    var currentState: EyeState {
        return state
    }
}
