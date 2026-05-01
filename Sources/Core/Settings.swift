import Foundation

/// 用户可配置设置项（UserDefaults 持久化）
class Settings {

    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let workDuration   = "workDuration"
        static let restDuration   = "restDuration"
        static let enforceRest    = "enforceRest"
        static let pauseOnLock    = "pauseOnLock"
        static let notifyOnWorkEnd = "notifyOnWorkEnd"
        static let notifyOnRestEnd = "notifyOnRestEnd"
        static let soundEnabled   = "soundEnabled"
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let statusBarStyle = "statusBarStyle"
        static let restWindowPosition = "restWindowPosition"
        static let themeMode      = "themeMode"
    }

    /// 外观主题
    enum ThemeMode: String, CaseIterable {
        case system = "system"  // 跟随系统
        case light  = "light"   // 强制亮色
        case dark   = "dark"    // 强制暗色

        var index: Int { ThemeMode.allCases.firstIndex(of: self) ?? 0 }
    }

    /// 状态栏样式
    enum StatusBarStyle: String, CaseIterable {
        case classic    = "classic"    // Working 29:59
        case minimal    = "minimal"    // 工作中 29:59
        case emoji      = "emoji"      // 💼 29:59
        case compact    = "compact"    // W 29:59
        case bracket    = "bracket"    // [工作中] 29:59
        case star       = "star"       // ☆工作中☆ 29:59
        case dots       = "dots"       // ◐◔◑◕
        case progressBar = "progressBar" // ████░░░░

        var index: Int {
            Settings.StatusBarStyle.allCases.firstIndex(of: self) ?? 0
        }
    }

    /// 休息弹窗位置
    enum RestWindowPosition: String, CaseIterable {
        case center    = "center"
        case topRight  = "topRight"

        var index: Int {
            Settings.RestWindowPosition.allCases.firstIndex(of: self) ?? 0
        }
    }

    // 默认值（秒）
    private static let defaultWork = 30 * 60  // 30 min
    private static let defaultRest =  5 * 60  // 5 min

    func registerDefaults() {
        defaults.register(defaults: [
            Keys.workDuration: Self.defaultWork,
            Keys.restDuration: Self.defaultRest,
            Keys.enforceRest: true,
            Keys.pauseOnLock: true,
            Keys.notifyOnWorkEnd: true,
            Keys.notifyOnRestEnd: false,
            Keys.soundEnabled: true,
            Keys.statusBarStyle: StatusBarStyle.classic.rawValue,
            Keys.restWindowPosition: RestWindowPosition.center.rawValue,
            Keys.themeMode: ThemeMode.system.rawValue,
        ])
    }

    /// 工作时长（秒）
    var workDuration: Int {
        get { defaults.integer(forKey: Keys.workDuration) }
        set { defaults.set(newValue, forKey: Keys.workDuration) }
    }

    /// 休息时长（秒）
    var restDuration: Int {
        get { defaults.integer(forKey: Keys.restDuration) }
        set { defaults.set(newValue, forKey: Keys.restDuration) }
    }

    /// 是否强制休息（不允许跳过）
    var enforceRest: Bool {
        get { defaults.bool(forKey: Keys.enforceRest) }
        set { defaults.set(newValue, forKey: Keys.enforceRest) }
    }

    /// 锁屏是否自动暂停
    var pauseOnLock: Bool {
        get { defaults.bool(forKey: Keys.pauseOnLock) }
        set { defaults.set(newValue, forKey: Keys.pauseOnLock) }
    }

    /// 工作结束时发送系统通知
    var notifyOnWorkEnd: Bool {
        get { defaults.bool(forKey: Keys.notifyOnWorkEnd) }
        set { defaults.set(newValue, forKey: Keys.notifyOnWorkEnd) }
    }

    /// 休息结束时发送系统通知
    var notifyOnRestEnd: Bool {
        get { defaults.bool(forKey: Keys.notifyOnRestEnd) }
        set { defaults.set(newValue, forKey: Keys.notifyOnRestEnd) }
    }

    /// 音效开关
    var soundEnabled: Bool {
        get { defaults.bool(forKey: Keys.soundEnabled) }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    /// 是否曾启动过（用于首次引导判断）
    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: Keys.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Keys.hasLaunchedBefore) }
    }

    /// 状态栏样式
    var statusBarStyle: StatusBarStyle {
        get {
            let raw = defaults.string(forKey: Keys.statusBarStyle) ?? StatusBarStyle.classic.rawValue
            return StatusBarStyle(rawValue: raw) ?? .classic
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.statusBarStyle) }
    }

    /// 休息弹窗位置
    var restWindowPosition: RestWindowPosition {
        get {
            let raw = defaults.string(forKey: Keys.restWindowPosition) ?? RestWindowPosition.center.rawValue
            return RestWindowPosition(rawValue: raw) ?? .center
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.restWindowPosition) }
    }

    /// 外观主题
    var themeMode: ThemeMode {
        get {
            let raw = defaults.string(forKey: Keys.themeMode) ?? ThemeMode.system.rawValue
            return ThemeMode(rawValue: raw) ?? .system
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.themeMode) }
    }
}
