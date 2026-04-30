import Foundation

/// 今日统计数据（内存记录，次日自动清零）
class StatsManager {

    static let shared = StatsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let date = "statsDate"
        static let rounds = "statsRounds"
        static let totalRestSeconds = "statsTotalRestSeconds"
    }

    private init() {}

    // MARK: - Properties

    var roundsCompletedToday: Int {
        get { ensureToday(); return defaults.integer(forKey: Keys.rounds) }
    }

    var totalRestMinutesToday: Int {
        get { ensureToday(); return defaults.integer(forKey: Keys.totalRestSeconds) / 60 }
    }

    // MARK: - Record

    func recordRoundCompleted() {
        ensureToday()
        defaults.set(defaults.integer(forKey: Keys.rounds) + 1, forKey: Keys.rounds)
    }

    func recordRestSeconds(_ seconds: Int) {
        ensureToday()
        defaults.set(defaults.integer(forKey: Keys.totalRestSeconds) + seconds, forKey: Keys.totalRestSeconds)
    }

    // MARK: - Helpers

    /// 确保数据是今天的，不是则重置
    private func ensureToday() {
        let today = todayString()
        if defaults.string(forKey: Keys.date) != today {
            defaults.set(today, forKey: Keys.date)
            defaults.set(0, forKey: Keys.rounds)
            defaults.set(0, forKey: Keys.totalRestSeconds)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
