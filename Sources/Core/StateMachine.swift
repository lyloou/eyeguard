import Foundation

/// 护眼卫士状态机
enum EyeState: Equatable {
    case idle              // 空闲
    case working           // 工作中
    case paused(remaining: Int)  // 已暂停（冻结的剩余秒数）
    case resting           // 休息中
    case awaitingActivity  // 休息已结束，等待键鼠活动后再开始工作

    var displayText: String {
        switch self {
        case .idle:             return L10n.stateDisplayIdle
        case .working:          return L10n.stateDisplayWorking
        case .paused:           return L10n.stateDisplayPaused
        case .resting:          return L10n.stateDisplayResting
        case .awaitingActivity: return L10n.stateDisplayAwaiting
        }
    }

    static func == (lhs: EyeState, rhs: EyeState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):               return true
        case (.working, .working):          return true
        case (.paused(let a), .paused(let b)): return a == b
        case (.resting, .resting):          return true
        case (.awaitingActivity, .awaitingActivity): return true
        default:                            return false
        }
    }
}
