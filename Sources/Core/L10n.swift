import Foundation

/// 本地化字符串管理
class L10n {

    // MARK: - 菜单 & 状态栏

    static var appName: String { "护眼卫士" }
    static var working: String { ns("Working") }
    static var paused: String { ns("Paused") }
    static var resting: String { ns("Resting") }
    static var idle: String { ns("Idle") }

    static func statusWorking(_ time: String) -> String { String(format: ns("Working %@"), time) }
    static func statusPaused(_ time: String) -> String { String(format: ns("Paused %@"), time) }
    static func statusResting(_ time: String) -> String { String(format: ns("Resting %@"), time) }
    static var statusIdle: String { ns("Idle") }

    // MARK: - 菜单项

    static var menuStart: String { ns("▶ Start") }
    static var menuResume: String { ns("▶ Resume") }
    static var menuPause: String { ns("⏸ Pause") }
    static var menuReset: String { ns("🔄 Reset") }
    static var menuRestNow: String { ns("⏰ Rest Now") }
    static var menuSettings: String { ns("⚙ Settings...") }
    static var menuAbout: String { ns("About EyeGuard") }
    static var menuQuit: String { ns("❌ Quit") }

    // MARK: - 设置窗口

    static var settingsTitle: String { ns("EyeGuard Settings") }
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

    // MARK: - 休息弹窗

    static var restTitle: String { ns("Take a Break") }
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

    // MARK: - 引导

    static var guideTitle: String { ns("Welcome to EyeGuard") }
    static var guideStep1: String { ns("Work for 30 min → rest 5 min") }
    static var guideStep2: String { ns("Rest window appears when work ends") }
    static var guideStep3: String { ns("Press Space/ESC or wait to continue") }
    static var guideGotIt: String { ns("Got it!") }

    // MARK: - 关于

    static var aboutTitle: String { ns("About EyeGuard") }
    static var aboutVersion: String { ns("Version %@") }

    // MARK: - 状态栏样式选项

    static var statusBarStyle: String { ns("Status Bar Style:") }
    static var styleClassic: String { ns("Classic (Working 29:59)") }
    static var styleMinimal: String { ns("Minimal (工作中 29:59)") }
    static var styleEmoji: String { ns("Emoji (💼工作中 29:59)") }
    static var styleCompact: String { ns("Compact (W 29:59)") }
    static var styleBracket: String { ns("Bracket ([工作中] 29:59)") }
    static var styleStar: String { ns("Star (☆工作中☆ 29:59)") }

    // MARK: - Helper

    private static func ns(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

extension Notification.Name {
    static let showAboutWindow = Notification.Name("showAboutWindow")
}
