import Foundation
import Carbon

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
        static let globalHotkeyToggleEnabled = "globalHotkeyToggleEnabled"
        static let globalHotkeyToggleKeyCode = "globalHotkeyToggleKeyCode"
        static let globalHotkeyToggleCarbonModifiers = "globalHotkeyToggleCarbonModifiers"
        static let globalHotkeyRestNowEnabled = "globalHotkeyRestNowEnabled"
        static let globalHotkeyRestNowKeyCode = "globalHotkeyRestNowKeyCode"
        static let globalHotkeyRestNowCarbonModifiers = "globalHotkeyRestNowCarbonModifiers"
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

    /// 默认「计时控制」快捷键：⌘⇧P（空闲开始、工作中暂停、已暂停继续；休息中不响应）
    private static let defaultToggleKeyCode = UInt32(kVK_ANSI_P)
    /// 默认「立即休息」快捷键：⌘⇧X
    private static let defaultRestNowKeyCode = UInt32(kVK_ANSI_X)
    private static let defaultHotkeyCarbonMods = UInt32(cmdKey | shiftKey)

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
            Keys.globalHotkeyToggleEnabled: true,
            Keys.globalHotkeyToggleKeyCode: Int(Self.defaultToggleKeyCode),
            Keys.globalHotkeyToggleCarbonModifiers: Int(Self.defaultHotkeyCarbonMods),
            Keys.globalHotkeyRestNowEnabled: true,
            Keys.globalHotkeyRestNowKeyCode: Int(Self.defaultRestNowKeyCode),
            Keys.globalHotkeyRestNowCarbonModifiers: Int(Self.defaultHotkeyCarbonMods),
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

    // MARK: - 全局快捷键（Carbon 虚拟键码 + 修饰键）

    /// 是否启用「计时控制」全局快捷键（空闲开始 / 工作中暂停 / 已暂停继续）
    var isGlobalHotkeyToggleEnabled: Bool {
        get { defaults.bool(forKey: Keys.globalHotkeyToggleEnabled) }
        set { defaults.set(newValue, forKey: Keys.globalHotkeyToggleEnabled) }
    }

    /// 「计时控制」快捷键虚拟键码（`kVK_*`）
    var globalHotkeyToggleKeyCode: UInt32 {
        get { UInt32(defaults.integer(forKey: Keys.globalHotkeyToggleKeyCode)) }
        set { defaults.set(Int(newValue), forKey: Keys.globalHotkeyToggleKeyCode) }
    }

    /// 「计时控制」快捷键 Carbon 修饰键位掩码
    var globalHotkeyToggleCarbonModifiers: UInt32 {
        get { UInt32(defaults.integer(forKey: Keys.globalHotkeyToggleCarbonModifiers)) }
        set { defaults.set(Int(newValue), forKey: Keys.globalHotkeyToggleCarbonModifiers) }
    }

    /// 是否启用「立即休息」全局快捷键
    var isGlobalHotkeyRestNowEnabled: Bool {
        get { defaults.bool(forKey: Keys.globalHotkeyRestNowEnabled) }
        set { defaults.set(newValue, forKey: Keys.globalHotkeyRestNowEnabled) }
    }

    /// 「立即休息」快捷键虚拟键码
    var globalHotkeyRestNowKeyCode: UInt32 {
        get { UInt32(defaults.integer(forKey: Keys.globalHotkeyRestNowKeyCode)) }
        set { defaults.set(Int(newValue), forKey: Keys.globalHotkeyRestNowKeyCode) }
    }

    /// 「立即休息」快捷键 Carbon 修饰键位掩码
    var globalHotkeyRestNowCarbonModifiers: UInt32 {
        get { UInt32(defaults.integer(forKey: Keys.globalHotkeyRestNowCarbonModifiers)) }
        set { defaults.set(Int(newValue), forKey: Keys.globalHotkeyRestNowCarbonModifiers) }
    }

    /// 关闭「计时控制」快捷键（不再注册全局按键）
    func clearGlobalHotkeyToggle() {
        isGlobalHotkeyToggleEnabled = false
    }

    /// 关闭「立即休息」快捷键
    func clearGlobalHotkeyRestNow() {
        isGlobalHotkeyRestNowEnabled = false
    }

    /// 写入「计时控制」快捷键并启用
    func setGlobalHotkeyToggle(keyCode: UInt32, carbonModifiers: UInt32) {
        globalHotkeyToggleKeyCode = keyCode
        globalHotkeyToggleCarbonModifiers = carbonModifiers
        isGlobalHotkeyToggleEnabled = true
    }

    /// 写入「立即休息」快捷键并启用
    func setGlobalHotkeyRestNow(keyCode: UInt32, carbonModifiers: UInt32) {
        globalHotkeyRestNowKeyCode = keyCode
        globalHotkeyRestNowCarbonModifiers = carbonModifiers
        isGlobalHotkeyRestNowEnabled = true
    }

    /// 是否与当前已启用的另一条快捷键组合完全相同
    func globalHotkeyConflicts(isToggle: Bool, keyCode: UInt32, carbonModifiers: UInt32) -> Bool {
        if isToggle {
            guard isGlobalHotkeyRestNowEnabled else { return false }
            return globalHotkeyRestNowKeyCode == keyCode
                && globalHotkeyRestNowCarbonModifiers == carbonModifiers
        }
        guard isGlobalHotkeyToggleEnabled else { return false }
        return globalHotkeyToggleKeyCode == keyCode
            && globalHotkeyToggleCarbonModifiers == carbonModifiers
    }
}
