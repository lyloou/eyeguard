import Foundation

/// 本地化字符串管理
enum L10n {

    // MARK: - 菜单 & 状态栏

    static var appName: String { ns("app.name") }
    static var idle: String { ns("Idle") }

    static func statusWorking(_ time: String) -> String { String(format: ns("Working %@"), time) }
    static func statusPaused(_ time: String) -> String { String(format: ns("Paused %@"), time) }
    static func statusResting(_ time: String) -> String { String(format: ns("Resting %@"), time) }
    static var statusIdle: String { ns("Idle") }
    static var statusAwaitingActivity: String { ns("Awaiting activity") }
    static var statusBarAwaitingActivity: String { ns("Resume: move or type") }

    static var stateDisplayIdle: String { ns("state.idle") }
    static var stateDisplayWorking: String { ns("state.working") }
    static var stateDisplayPaused: String { ns("state.paused") }
    static var stateDisplayResting: String { ns("state.resting") }
    static var stateDisplayAwaiting: String { ns("state.awaiting") }

    static func statusBarClassicWorking(_ time: String) -> String { String(format: ns("status.classic.working"), time) }
    static func statusBarClassicPaused(_ time: String) -> String { String(format: ns("status.classic.paused"), time) }
    static func statusBarClassicResting(_ time: String) -> String { String(format: ns("status.classic.resting"), time) }

    static func statusBarBracketWorking(_ time: String) -> String { String(format: ns("status.bracket.working"), time) }
    static func statusBarBracketPaused(_ time: String) -> String { String(format: ns("status.bracket.paused"), time) }
    static func statusBarBracketResting(_ time: String) -> String { String(format: ns("status.bracket.resting"), time) }
    static var statusBarBracketAwaiting: String { ns("status.bracket.awaiting") }

    static func statusBarStarWorking(_ time: String) -> String { String(format: ns("status.star.working"), time) }
    static func statusBarStarPaused(_ time: String) -> String { String(format: ns("status.star.paused"), time) }
    static func statusBarStarResting(_ time: String) -> String { String(format: ns("status.star.resting"), time) }
    static var statusBarStarAwaiting: String { ns("status.star.awaiting") }

    static func statusBarEmojiWorking(_ time: String) -> String { String(format: ns("status.emoji.working"), time) }
    static func statusBarEmojiPaused(_ time: String) -> String { String(format: ns("status.emoji.paused"), time) }
    static func statusBarEmojiResting(_ time: String) -> String { String(format: ns("status.emoji.resting"), time) }
    static func statusBarEmojiAwaiting(_ time: String) -> String { String(format: ns("status.emoji.awaiting"), L10n.statusBarAwaitingActivity) }

    static func statusBarCompactWorking(_ time: String) -> String { String(format: ns("status.compact.working"), time) }
    static func statusBarCompactPaused(_ time: String) -> String { String(format: ns("status.compact.paused"), time) }
    static func statusBarCompactResting(_ time: String) -> String { String(format: ns("status.compact.resting"), time) }
    static var statusBarCompactAwaiting: String { ns("status.compact.awaiting") }

    static func statusBarDotsWorking(_ dot: String, _ time: String) -> String { String(format: ns("status.dots.working"), dot, time) }
    static func statusBarDotsPaused(_ time: String) -> String { String(format: ns("status.dots.paused"), time) }
    static func statusBarDotsResting(_ dot: String, _ time: String) -> String { String(format: ns("status.dots.resting"), dot, time) }
    static var statusBarDotsAwaiting: String { ns("status.dots.awaiting") }

    static func statusBarProgressWorking(_ bar: String, _ time: String) -> String { String(format: ns("status.progress.working"), bar, time) }
    static func statusBarProgressPaused(_ time: String) -> String { String(format: ns("status.progress.paused"), time) }
    static func statusBarProgressResting(_ bar: String, _ time: String) -> String { String(format: ns("status.progress.resting"), bar, time) }
    static var statusBarProgressAwaiting: String { ns("status.progress.awaiting") }

    static func previewClassic(_ time: String) -> String { String(format: ns("preview.classic"), time) }
    static func previewMinimal(_ time: String) -> String { String(format: ns("preview.minimal"), time) }
    static func previewEmoji(_ time: String) -> String { String(format: ns("preview.emoji"), time) }
    static func previewCompact(_ time: String) -> String { String(format: ns("preview.compact"), time) }
    static func previewBracket(_ time: String) -> String { String(format: ns("preview.bracket"), time) }
    static func previewStar(_ time: String) -> String { String(format: ns("preview.star"), time) }
    static func previewDots(_ time: String) -> String { String(format: ns("preview.dots"), time) }
    static func previewProgressBar(_ time: String) -> String { String(format: ns("preview.progressBar"), time) }

    // MARK: - 菜单项

    static var menuStart: String { ns("▶ Start") }
    static var menuResume: String { ns("▶ Resume") }
    static var menuPause: String { ns("⏸ Pause") }
    static var menuReset: String { ns("🔄 Reset") }
    static var menuRestNow: String { ns("⏰ Rest Now") }
    static var menuDimScreen: String { ns("🌑 Dim Screen") }
    static var menuBrightScreen: String { ns("☀️ Bright Screen") }
    static var menuSettings: String { ns("⚙ Settings...") }
    static var menuAbout: String { ns("About EyeGuard") }
    static var menuQuit: String { ns("❌ Quit") }

    // MARK: - 设置窗口

    static var settingsTitle: String { ns("settings.title") }
    static var sectionSystem: String { ns("settings.section.system") }
    static var sectionShortcuts: String { ns("settings.section.shortcuts") }
    static var sectionTimer: String { ns("settings.section.timer") }
    static var sectionBehavior: String { ns("settings.section.behavior") }
    static var sectionNotifications: String { ns("settings.section.notifications") }

    static var languageLabel: String { ns("settings.language.label") }
    static var languageSystem: String { ns("settings.language.system") }
    static var languageEnglish: String { ns("settings.language.english") }
    static var languageChinese: String { ns("settings.language.chinese") }

    static var launchAtLoginLabel: String { ns("settings.launchAtLogin.label") }
    static var launchAtLoginSubtitle: String { ns("settings.launchAtLogin.subtitle") }
    static var statusBarStyleLabel: String { ns("settings.statusBarStyle.label") }
    static var breakWindowPositionLabel: String { ns("settings.breakWindowPosition.label") }
    static var appearanceLabel: String { ns("settings.appearance.label") }
    static var themeSystem: String { ns("settings.theme.system") }
    static var themeLight: String { ns("settings.theme.light") }
    static var themeDark: String { ns("settings.theme.dark") }

    static var hotkeyTimerTitle: String { ns("settings.hotkey.timer.title") }
    static var hotkeyTimerSubtitle: String { ns("settings.hotkey.timer.subtitle") }
    static var hotkeyTimerDetail: String { ns("settings.hotkey.timer.detail") }
    static var hotkeyRestNowTitle: String { ns("settings.hotkey.restNow.title") }
    static var hotkeyRestNowSubtitle: String { ns("settings.hotkey.restNow.subtitle") }
    static var hotkeyRestNowDetail: String { ns("settings.hotkey.restNow.detail") }
    static var hotkeyPressKeys: String { ns("settings.hotkey.pressKeys") }
    static var hotkeyClickToSet: String { ns("settings.hotkey.clickToSet") }
    static var hotkeyClearTooltip: String { ns("settings.hotkey.clearTooltip") }

    static var workDurationLabel: String { ns("settings.workDuration.label") }
    static var restDurationLabel: String { ns("settings.restDuration.label") }
    static var durationUnitMin: String { ns("settings.duration.min") }

    static var enforceRestLabel: String { ns("settings.enforceRest.label") }
    static var enforceRestSubtitle: String { ns("settings.enforceRest.subtitle") }
    static var focusBreakWindowLabel: String { ns("settings.focusBreakWindow.label") }
    static var focusBreakWindowSubtitle: String { ns("settings.focusBreakWindow.subtitle") }
    static var waitForActivityLabel: String { ns("settings.waitForActivity.label") }
    static var waitForActivitySubtitle: String { ns("settings.waitForActivity.subtitle") }
    static var pauseOnLockLabel: String { ns("settings.pauseOnLock.label") }
    static var pauseOnLockSubtitle: String { ns("settings.pauseOnLock.subtitle") }

    static var notifyWorkEndLabel: String { ns("settings.notifyWorkEnd.label") }
    static var notifyWorkEndSubtitle: String { ns("settings.notifyWorkEnd.subtitle") }
    static var notifyRestEndLabel: String { ns("settings.notifyRestEnd.label") }
    static var notifyRestEndSubtitle: String { ns("settings.notifyRestEnd.subtitle") }
    static var soundEnabledLabel: String { ns("settings.sound.label") }
    static var soundEnabledSubtitle: String { ns("settings.sound.subtitle") }

    static var styleClassic: String { ns("style.classic") }
    static var styleMinimal: String { ns("style.minimal") }
    static var styleEmoji: String { ns("style.emoji") }
    static var styleCompact: String { ns("style.compact") }
    static var styleBracket: String { ns("style.bracket") }
    static var styleStar: String { ns("style.star") }
    static var styleDots: String { ns("style.dots") }
    static var styleProgressBar: String { ns("style.progressBar") }

    static var workDuration: String { ns("Work Duration:") }
    static var restDuration: String { ns("Rest Duration:") }
    static var minutes: String { ns("minutes") }
    static var enforceRest: String { ns("Enforce Rest (no skip)") }
    static var pauseOnLock: String { ns("Pause on Lock") }
    static var notifyOnWorkEnd: String { ns("Notify on Work End") }
    static var notifyOnRestEnd: String { ns("Notify on Rest End") }
    static var soundEnabled: String { ns("Sound Effects") }
    static var loginItem: String { ns("Launch at Login") }
    static var save: String { ns("Save") }
    static var statusBarStyle: String { ns("Status Bar Style:") }

    // MARK: - 休息弹窗

    static var restTitle: String { ns("Take a Break") }
    static var restSubtitle: String { ns("rest.subtitle") }
    static var restBreakBadge: String { ns("rest.breakBadge") }
    static var restBody: String { ns("Rest") }
    static var skipRest: String { ns("Skip Rest") }

    // MARK: - 通知

    static var notifyRestStartTitle: String { ns("Take a Break 🎉") }
    static func notifyRestStartBody(work: Int, rest: Int) -> String {
        String(format: ns("Worked %d min, rest %d min"), work, rest)
    }
    static var notifyRestEndTitle: String { ns("Back to Work 💪") }
    static var notifyRestEndBody: String { ns("Rest done, start a new session") }

    // MARK: - 统计

    static var todayStats: String { ns("Today's Stats") }
    static func roundsCompleted(_ n: Int) -> String { String(format: ns("%d rounds completed"), n) }
    static func totalRest(_ min: Int) -> String { String(format: ns("%d min rested"), min) }
    static var menuViewStats: String { ns("stats.menu.view") }

    static var statsTitle: String { ns("stats.title") }
    static func statsTodaySummary(work: Int, rest: Int, rounds: Int) -> String {
        String(format: ns("stats.today.summary"), work, rest, rounds)
    }
    static var statsRangeLabel: String { ns("stats.range.label") }
    static var statsPreset7: String { ns("stats.preset.7") }
    static var statsPreset14: String { ns("stats.preset.14") }
    static var statsPreset30: String { ns("stats.preset.30") }
    static var statsFrom: String { ns("stats.from") }
    static var statsTo: String { ns("stats.to") }
    static var statsInvalidRange: String { ns("stats.range.invalid") }
    static func statsRangeTooLong(_ maxDays: Int) -> String {
        String(format: ns("stats.range.tooLong"), maxDays)
    }
    static func statsRangeSummary(days: Int, work: Int, rest: Int, rounds: Int, avgWork: Int, avgRest: Int) -> String {
        String(format: ns("stats.range.summary"), days, work, rest, rounds, avgWork, avgRest)
    }
    static var statsLegendWork: String { ns("stats.legend.work") }
    static var statsLegendRest: String { ns("stats.legend.rest") }
    static var statsChartEmpty: String { ns("stats.chart.empty") }
    static var statsYAxisUnit: String { ns("stats.yAxis.unit") }
    static var statsMetricWork: String { ns("stats.metric.work") }
    static var statsMetricRest: String { ns("stats.metric.rest") }
    static var statsMetricRounds: String { ns("stats.metric.rounds") }
    static var statsMetricUnitMin: String { ns("stats.metric.unit.min") }
    static var statsMetricUnitRound: String { ns("stats.metric.unit.round") }
    static var statsRangeTitle: String { ns("stats.range.title") }

    // MARK: - 引导

    static var guideTitle: String { ns("Welcome to EyeGuard") }
    static var guideStep1: String { ns("Work for 30 min → rest 5 min") }
    static var guideStep2: String { ns("Rest window appears when work ends") }
    static var guideStep3: String { ns("Press Space/ESC or wait to continue") }
    static var guideGotIt: String { ns("Got it!") }
    static var guideNext: String { ns("guide.next") }
    static var guideSkip: String { ns("guide.skip") }
    static var aboutDescription: String { ns("about.description") }

    // MARK: - 关于

    static var aboutTitle: String { ns("About EyeGuard") }
    static var aboutTagline: String { ns("about.tagline") }
    static var aboutVersion: String { ns("Version %@") }

    // MARK: - 休息弹窗位置

    static var restWindowPosition: String { ns("Rest Window Position:") }
    static var positionCenter: String { ns("Center") }
    static var positionTopRight: String { ns("Top Right") }

    // MARK: - Helper

    /// 按本地化 key 取字符串（供设置页控件 `identifier` 刷新）。
    static func string(forKey key: String) -> String {
        ns(key)
    }

    private static func ns(_ key: String) -> String {
        Localization.string(key)
    }
}

extension Notification.Name {
    static let showAboutWindow = Notification.Name("showAboutWindow")
    static let showStatsWindow = Notification.Name("showStatsWindow")
    static let settingsDidChange = Notification.Name("settingsDidChange")
}
