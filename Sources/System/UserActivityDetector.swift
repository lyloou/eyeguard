import CoreGraphics
import Foundation

/// 基于系统 HID 空闲时间检测用户是否近期有鼠标或键盘活动。
enum UserActivityDetector {

    /// 判定为「刚有活动」的空闲上限（秒）。
    static let recentActivityThreshold: TimeInterval = 2.0

    /// 轮询时判定「出现新活动」相对基线的最小下降量（秒）。
    static let activityDropEpsilon: TimeInterval = 0.1

    /// 返回自上次鼠标移动或按键以来较短一侧的空闲秒数。
    static func combinedIdleSeconds() -> TimeInterval {
        let mouseIdle = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: CGEventType.mouseMoved
        )
        let keyIdle = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: CGEventType.keyDown
        )
        return min(mouseIdle, keyIdle)
    }

    /// 是否在阈值内存在键鼠活动（常用于休息结束瞬间是否立即开工）。
    static func hasRecentActivity(threshold: TimeInterval = recentActivityThreshold) -> Bool {
        combinedIdleSeconds() < threshold
    }

    /// 自记录基线以来是否出现新的键鼠活动（空闲时间明显低于基线）。
    static func hasNewActivitySince(baselineIdle: TimeInterval) -> Bool {
        combinedIdleSeconds() + activityDropEpsilon < baselineIdle
    }
}
