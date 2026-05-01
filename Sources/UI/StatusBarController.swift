import AppKit

/// 状态栏菜单控制器
class StatusBarController: NSObject {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    weak var timerManager: TimerManager?

    // 菜单项
    private var statusMenuItem: NSMenuItem!
    private var startMenuItem: NSMenuItem!
    private var pauseMenuItem: NSMenuItem!
    private var resetMenuItem: NSMenuItem!
    private var restNowMenuItem: NSMenuItem!

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
            // 使用 SF Symbol 作为状态栏图标（template 模式，自动适配深浅色）
            if let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "EyeGuard") {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                button.image?.isTemplate = true
            } else {
                button.title = L10n.appName
            }
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

        // 开始/暂停
        startMenuItem = NSMenuItem(title: L10n.menuStart, action: #selector(startClicked), keyEquivalent: "")
        startMenuItem.target = self
        menu.addItem(startMenuItem)

        pauseMenuItem = NSMenuItem(title: L10n.menuPause, action: #selector(pauseClicked), keyEquivalent: "")
        pauseMenuItem.target = self
        menu.addItem(pauseMenuItem)

        resetMenuItem = NSMenuItem(title: L10n.menuReset, action: #selector(resetClicked), keyEquivalent: "")
        resetMenuItem.target = self
        menu.addItem(resetMenuItem)

        // 立即休息
        restNowMenuItem = NSMenuItem(title: L10n.menuRestNow, action: #selector(restNowClicked), keyEquivalent: "")
        restNowMenuItem.target = self
        menu.addItem(restNowMenuItem)

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

    @objc private func startClicked() {
        timerManager?.start()
    }

    @objc private func pauseClicked() {
        guard let manager = timerManager else { return }
        if case .paused = manager.currentState {
            manager.resume()
        } else {
            manager.pause()
        }
    }

    @objc private func resetClicked() {
        timerManager?.reset()
    }

    @objc private func restNowClicked() {
        timerManager?.restNow()
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
            startMenuItem.title = L10n.menuStart
            startMenuItem.isEnabled = true
            pauseMenuItem.title = L10n.menuPause
            pauseMenuItem.isEnabled = false
            resetMenuItem.isEnabled = false
            restNowMenuItem.isEnabled = false
            statusItem.button?.title = L10n.appName

        case .working:
            statusMenuItem.title = L10n.statusWorking(timeStr)
            startMenuItem.title = L10n.menuStart
            startMenuItem.isEnabled = false
            pauseMenuItem.title = L10n.menuPause
            pauseMenuItem.isEnabled = true
            resetMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = true
            statusItem.button?.title = formatStatusBarText(state: .working, timeStr: timeStr, remaining: remaining)

        case .paused(let frozen):
            statusMenuItem.title = L10n.statusPaused(formatTime(frozen))
            startMenuItem.title = L10n.menuResume
            startMenuItem.isEnabled = true
            pauseMenuItem.title = L10n.menuPause
            pauseMenuItem.isEnabled = false
            resetMenuItem.isEnabled = true
            restNowMenuItem.isEnabled = true
            statusItem.button?.title = formatStatusBarText(state: .paused(remaining: frozen), timeStr: formatTime(frozen), remaining: frozen)

        case .resting:
            statusMenuItem.title = L10n.statusResting(timeStr)
            startMenuItem.isEnabled = false
            pauseMenuItem.isEnabled = false
            resetMenuItem.isEnabled = false
            restNowMenuItem.isEnabled = false
            statusItem.button?.title = formatStatusBarText(state: .resting, timeStr: timeStr, remaining: remaining)
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
            case .working: return "工作中 \(timeStr)"
            case .paused:  return "已暂停 \(timeStr)"
            case .resting: return "休息中 \(timeStr)"
            }
        case .emoji:
            switch state {
            case .idle:    return L10n.appName
            case .working: return "💼工作中 \(timeStr)"
            case .paused:  return "⏸已暂停 \(timeStr)"
            case .resting: return "🌿休息中 \(timeStr)"
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
        case .pureTime:
            // 纯时间：只有倒计时，无状态前缀
            switch state {
            case .idle:    return L10n.appName
            case .working: return timeStr
            case .paused:  return timeStr
            case .resting: return timeStr
            }
        case .dots:
            // 进度点：◐◔◑◕ 动态圆弧表示进度
            let total = totalSeconds(for: state)
            let filled = total > 0 ? (total - remaining) * 4 / total : 0
            let dots = ["◐", "◔", "◑", "◕"]
            switch state {
            case .idle:    return L10n.appName
            case .working: return "\(dots[min(filled, 3)])工作中 \(timeStr)"
            case .paused:  return "⏸ \(timeStr)"
            case .resting: return "\(dots[min(filled, 3)])休息中 \(timeStr)"
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
}

// MARK: - TimerManager 用到的计算属性

extension TimerManager {
    var currentState: EyeState {
        return state
    }
}
