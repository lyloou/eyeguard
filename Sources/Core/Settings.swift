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
            Keys.notifyOnWorkEnd: true,   // 默认开启工作结束通知
            Keys.notifyOnRestEnd: false   // 默认关闭休息结束通知
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
}
