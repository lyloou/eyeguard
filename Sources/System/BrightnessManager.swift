import Foundation
import CoreGraphics

/// 屏幕亮度管理器
/// 使用 Apple 私有 API DisplayServicesSetBrightness 调节所有显示器亮度
final class BrightnessManager {

    static let shared = BrightnessManager()

    private init() {}

    /// 私有 API：设置显示器亮度
    @_silgen_name("DisplayServicesSetBrightness")
    private static func DisplayServicesSetBrightness(_ display: CGDirectDisplayID, _ brightness: Float) -> Int32

    /// 暗屏（亮度 = 0）
    func dim() {
        setBrightness(0.0)
    }

    /// 亮屏（亮度 = 80%）
    func bright() {
        setBrightness(0.8)
    }

    /// 设置指定亮度
    /// - Parameter value: 亮度值 0.0~1.0，超出范围自动 clamp
    func setBrightness(_ value: Float) {
        let clamped = max(0.0, min(1.0, value))

        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displays, &displayCount)

        for displayID in displays {
            _ = BrightnessManager.DisplayServicesSetBrightness(displayID, clamped)
        }
    }
}
