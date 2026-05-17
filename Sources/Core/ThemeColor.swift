import AppKit

/// 动态颜色 token — 自动适应明暗主题
enum ThemeColor {

    /// 卡片背景（亮色：black 4%，暗色：white 7%）
    static var cardBackground: NSColor {
        dynamic(
            light: NSColor.black.withAlphaComponent(0.04),
            dark:  NSColor.white.withAlphaComponent(0.07)
        )
    }

    /// 卡片边框（亮色：black 8%，暗色：white 10%）
    static var cardBorder: NSColor {
        dynamic(
            light: NSColor.black.withAlphaComponent(0.08),
            dark:  NSColor.white.withAlphaComponent(0.10)
        )
    }

    /// 卡片内分割线
    static var cardDivider: NSColor {
        dynamic(
            light: NSColor.black.withAlphaComponent(0.06),
            dark:  NSColor.white.withAlphaComponent(0.07)
        )
    }

    /// Jade 绿强调色（明暗一致）
    static var accent: NSColor {
        NSColor(red: 0.22, green: 0.78, blue: 0.55, alpha: 1.0)
    }

    /// 浅版强调色（用于徽章背景等）
    static var accentSubtle: NSColor {
        dynamic(
            light: NSColor(red: 0.22, green: 0.78, blue: 0.55, alpha: 0.12),
            dark:  NSColor(red: 0.22, green: 0.78, blue: 0.55, alpha: 0.18)
        )
    }

    /// 统计图休息折线色（暖琥珀，与工作绿区分）
    static var chartRest: NSColor {
        dynamic(
            light: NSColor(red: 0.92, green: 0.55, blue: 0.18, alpha: 1.0),
            dark:  NSColor(red: 0.98, green: 0.62, blue: 0.28, alpha: 1.0)
        )
    }

    /// 统计图绘图区背景
    static var chartPlotBackground: NSColor {
        dynamic(
            light: NSColor.black.withAlphaComponent(0.02),
            dark:  NSColor.white.withAlphaComponent(0.04)
        )
    }

    /// 浮层叠加色（About 窗口用，亮色 3%，暗色 30%）
    static var overlayTint: NSColor {
        dynamic(
            light: NSColor.black.withAlphaComponent(0.03),
            dark:  NSColor.black.withAlphaComponent(0.30)
        )
    }

    // MARK: - Internal

    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua: return dark
            default:        return light
            }
        }
    }
}
