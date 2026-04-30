import Foundation

/// 护眼卫士状态机
enum EyeState: Equatable {
    case idle              // 空闲
    case working           // 工作中
    case paused(remaining: Int)  // 已暂停（冻结的剩余秒数）
    case resting           // 休息中

    var displayText: String {
        switch self {
        case .idle:        return "护眼卫士"
        case .working:     return "工作中"
        case .paused:      return "已暂停"
        case .resting:     return "休息中"
        }
    }

    static func == (lhs: EyeState, rhs: EyeState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):               return true
        case (.working, .working):          return true
        case (.paused(let a), .paused(let b)): return a == b
        case (.resting, .resting):          return true
        default:                            return false
        }
    }
}
