import Foundation

/// 单日运行统计快照。
struct DailyStats: Codable, Equatable {

    let date: String
    var workSeconds: Int
    var restSeconds: Int
    var rounds: Int

    /// 当日累计工作分钟数（向下取整）。
    var workMinutes: Int { workSeconds / 60 }

    /// 当日累计休息分钟数（向下取整）。
    var restMinutes: Int { restSeconds / 60 }
}
