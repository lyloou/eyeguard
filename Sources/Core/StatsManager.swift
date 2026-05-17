import Foundation

/// 今日与历史运行统计（UserDefaults 持久化，历史全部保留不裁剪）。
class StatsManager {

    static let shared = StatsManager()

    /// 自定义日期区间允许的最大天数。
    static let maxCustomRangeDays = 90

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private enum Keys {
        static let date = "statsDate"
        static let rounds = "statsRounds"
        static let totalRestSeconds = "statsTotalRestSeconds"
        static let totalWorkSeconds = "statsTotalWorkSeconds"
        static let history = "statsDailyHistory"
    }

    private var historyByDate: [String: DailyStats] = [:]

    private init() {
        loadHistory()
        ensureToday()
    }

    // MARK: - Today

    /// 今日完成的休息轮次数。
    var roundsCompletedToday: Int {
        get { ensureToday(); return defaults.integer(forKey: Keys.rounds) }
    }

    /// 今日累计休息分钟数。
    var totalRestMinutesToday: Int {
        get { ensureToday(); return defaults.integer(forKey: Keys.totalRestSeconds) / 60 }
    }

    /// 今日累计工作分钟数。
    var totalWorkMinutesToday: Int {
        get { ensureToday(); return defaults.integer(forKey: Keys.totalWorkSeconds) / 60 }
    }

    // MARK: - Record

    /// 记录完成一轮工作→休息。
    func recordRoundCompleted() {
        ensureToday()
        defaults.set(defaults.integer(forKey: Keys.rounds) + 1, forKey: Keys.rounds)
    }

    /// 累加实际休息秒数。
    func recordRestSeconds(_ seconds: Int) {
        guard seconds > 0 else { return }
        ensureToday()
        defaults.set(defaults.integer(forKey: Keys.totalRestSeconds) + seconds, forKey: Keys.totalRestSeconds)
    }

    /// 累加一秒工作时长（仅在 `.working` 时由计时器调用）。
    func recordWorkSecond() {
        ensureToday()
        defaults.set(defaults.integer(forKey: Keys.totalWorkSeconds) + 1, forKey: Keys.totalWorkSeconds)
    }

    // MARK: - Query

    /// 返回闭区间内每一天的统计（含起止日，缺失日记为零）。
    func dailyStats(from startDate: Date, to endDate: Date) -> [DailyStats] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return [] }

        var result: [DailyStats] = []
        var cursor = start
        while cursor <= end {
            let key = dateFormatter.string(from: cursor)
            result.append(snapshot(for: key))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    /// 最近 N 天（含今天）的每日统计。
    func dailyStats(lastDays: Int) -> [DailyStats] {
        let days = max(1, lastDays)
        let end = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else { return [] }
        return dailyStats(from: start, to: end)
    }

    /// 对区间数据求合计。
    func totals(in stats: [DailyStats]) -> (workMinutes: Int, restMinutes: Int, rounds: Int) {
        let work = stats.reduce(0) { $0 + $1.workMinutes }
        let rest = stats.reduce(0) { $0 + $1.restMinutes }
        let rounds = stats.reduce(0) { $0 + $1.rounds }
        return (work, rest, rounds)
    }

    /// 供 CLI `stats` 返回的最近 7 日摘要（字典数组）。
    func historySummaryForCLI(lastDays: Int = 7) -> [[String: Any]] {
        dailyStats(lastDays: lastDays).map { day in
            [
                "date": day.date,
                "workMinutes": day.workMinutes,
                "restMinutes": day.restMinutes,
                "rounds": day.rounds,
            ]
        }
    }

    // MARK: - Helpers

    /// 确保今日键存在；跨日时归档昨日并清零。
    private func ensureToday() {
        let today = todayString()
        let storedDate = defaults.string(forKey: Keys.date)

        if let storedDate, storedDate != today {
            archiveDay(
                date: storedDate,
                rounds: defaults.integer(forKey: Keys.rounds),
                workSeconds: defaults.integer(forKey: Keys.totalWorkSeconds),
                restSeconds: defaults.integer(forKey: Keys.totalRestSeconds)
            )
            defaults.set(today, forKey: Keys.date)
            defaults.set(0, forKey: Keys.rounds)
            defaults.set(0, forKey: Keys.totalRestSeconds)
            defaults.set(0, forKey: Keys.totalWorkSeconds)
        } else if storedDate == nil {
            defaults.set(today, forKey: Keys.date)
        }
    }

    /// 读取指定日期的统计（今天在 UserDefaults，历史在归档表）。
    private func snapshot(for date: String) -> DailyStats {
        if date == todayString() {
            ensureToday()
            return DailyStats(
                date: date,
                workSeconds: defaults.integer(forKey: Keys.totalWorkSeconds),
                restSeconds: defaults.integer(forKey: Keys.totalRestSeconds),
                rounds: defaults.integer(forKey: Keys.rounds)
            )
        }
        return historyByDate[date]
            ?? DailyStats(date: date, workSeconds: 0, restSeconds: 0, rounds: 0)
    }

    /// 将已结束的一天写入历史（有数据才写入）。
    private func archiveDay(date: String, rounds: Int, workSeconds: Int, restSeconds: Int) {
        guard rounds > 0 || workSeconds > 0 || restSeconds > 0 else { return }
        historyByDate[date] = DailyStats(
            date: date,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            rounds: rounds
        )
        saveHistory()
    }

    private func loadHistory() {
        guard let data = defaults.data(forKey: Keys.history),
              let decoded = try? JSONDecoder().decode([String: DailyStats].self, from: data) else {
            historyByDate = [:]
            return
        }
        historyByDate = decoded
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(historyByDate) else { return }
        defaults.set(data, forKey: Keys.history)
    }

    private func todayString() -> String {
        dateFormatter.string(from: Date())
    }
}
