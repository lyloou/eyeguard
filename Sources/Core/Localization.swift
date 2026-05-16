import Foundation

/// 应用内语言 Bundle 解析（支持跟随系统 / 强制英文 / 强制简体中文）。
enum Localization {

    /// 解析后用于 `NSLocalizedString` 的 Bundle。
    static var bundle: Bundle {
        switch Settings.shared.appLanguage {
        case .system:
            return Bundle.main
        case .en, .zhHans:
            guard let id = Settings.shared.appLanguage.localeIdentifier else { return Bundle.main }
            return languageBundle(for: id) ?? Bundle.main
        }
    }

    /// 当前生效的语言代码（`en` 或 `zh-Hans`），用于非 strings 资源（如内置语录）。
    static var effectiveLanguageCode: String {
        switch Settings.shared.appLanguage {
        case .system:
            let preferred = Bundle.main.preferredLocalizations.first ?? "en"
            if preferred.hasPrefix("zh") { return "zh-Hans" }
            return "en"
        case .en:
            return "en"
        case .zhHans:
            return "zh-Hans"
        }
    }

    /// 是否为简体中文界面。
    static var isChinese: Bool {
        effectiveLanguageCode.hasPrefix("zh")
    }

    /// 加载指定 `.lproj` 的 Bundle。
    static func languageBundle(for localeIdentifier: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }

    /// 按 key 取本地化字符串。
    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }
}
