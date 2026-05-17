import AppKit

// MARK: - Window chrome

/// 为设置/统计等窗口铺设毛玻璃背景、顶光与标题区。
enum EyeGuardWindowChrome {

    /// 配置面板窗口样式（透明标题栏 + 全尺寸内容）。
    static func configure(panel: NSPanel) {
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.styleMask.insert(.fullSizeContentView)
    }

    /// 在 `contentView` 上创建毛玻璃根视图。
    static func installBackground(on contentView: NSView) -> NSVisualEffectView {
        let blur = NSVisualEffectView(frame: contentView.bounds)
        blur.material = .windowBackground
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 12
        blur.layer?.masksToBounds = true
        blur.autoresizingMask = [.width, .height]
        contentView.addSubview(blur)

        let overlay = ChromeOverlayView(frame: blur.bounds)
        overlay.autoresizingMask = [.width, .height]
        blur.addSubview(overlay)

        return blur
    }

    /// 顶部翡翠光带。
    static func addTopGlow(to blur: NSView) -> NSView {
        let glow = NSView()
        glow.wantsLayer = true
        glow.layer?.backgroundColor = ThemeColor.accent.withAlphaComponent(0.16).cgColor
        glow.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(glow)
        NSLayoutConstraint.activate([
            glow.topAnchor.constraint(equalTo: blur.topAnchor),
            glow.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            glow.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            glow.heightAnchor.constraint(equalToConstant: 3),
        ])
        return glow
    }

    /// 创建窗口主标题。
    static func makeTitleLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    /// 创建窗口副标题。
    static func makeSubtitleLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    /// 生成「标题 · 描述」单行富文本顶栏。
    static func attributedHeader(title: String, subtitle: String, separator: String = " · ") -> NSAttributedString {
        let full = title + separator + subtitle
        let attr = NSMutableAttributedString(string: full)
        let titleRange = (full as NSString).range(of: title)
        let sepRange = (full as NSString).range(of: separator)
        let subRange = (full as NSString).range(of: subtitle)
        attr.addAttributes([
            .font: NSFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: NSColor.labelColor,
        ], range: titleRange)
        attr.addAttributes([
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ], range: sepRange)
        attr.addAttributes([
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.secondaryLabelColor,
        ], range: subRange)
        return attr
    }

    /// 根据 `contentLayoutRect` 计算标题顶部约束常量。
    static func titleTopInset(for window: NSWindow?, extraPadding: CGFloat = 10) -> CGFloat {
        guard let window, let contentView = window.contentView else { return 52 }
        window.layoutIfNeeded()
        let contentHeight = contentView.bounds.height
        let layoutHeight = window.contentLayoutRect.height
        let titleBarHeight = contentHeight > 0 ? contentHeight - layoutHeight : 28
        return max(titleBarHeight, 28) + extraPadding
    }
}

// MARK: - Section header (settings)

/// 设置页分组标题（左侧强调条 + 大写标签）。
final class EyeGuardSectionHeaderView: NSView {

    private let accentBar = NSView()
    private let label = NSTextField(labelWithString: "")

    init(titleKey: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        accentBar.wantsLayer = true
        accentBar.layer?.backgroundColor = ThemeColor.accent.cgColor
        accentBar.layer?.cornerRadius = 1.5
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        label.stringValue = L10n.string(forKey: titleKey)
        label.identifier = NSUserInterfaceItemIdentifier(titleKey)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28),
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            accentBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: 3),
            accentBar.heightAnchor.constraint(equalToConstant: 14),
            label.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Menu helpers

/// 状态栏菜单 UI 辅助方法。
enum StatusMenuStyle {

    static let minimumWidth: CGFloat = 260

    /// 配置菜单整体样式。
    static func apply(to menu: NSMenu) {
        menu.minimumWidth = minimumWidth
    }

    /// 将当前主题应用到菜单、子菜单及自定义 view（状态栏菜单不继承 `NSApp.appearance`）。
    static func applyAppearance(to menu: NSMenu) {
        let appearance = Settings.shared.themeMode.nsAppearance
        menu.appearance = appearance
        for item in menu.items {
            item.view?.appearance = appearance
            if let submenu = item.submenu {
                applyAppearance(to: submenu)
            }
        }
    }

    /// 添加分组标题行（不可点击），返回该项以便主题切换时刷新。
    @discardableResult
    static func addSection(_ title: String, to menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false
        updateSection(item, title: title)
        menu.addItem(item)
        return item
    }

    /// 更新分组标题的 attributed 样式（语言或主题变更时调用）。
    static func updateSection(_ item: NSMenuItem, title: String) {
        item.attributedTitle = sectionAttributedTitle(title)
    }

    /// 构建分组标题的 attributed 字符串。
    static func sectionAttributedTitle(_ title: String) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.tertiaryLabelColor,
            .kern: 0.6,
        ]
        return NSAttributedString(string: title.uppercased(), attributes: attrs)
    }

    /// 创建带 SF Symbol 的菜单项。
    static func item(
        title: String,
        symbol: String,
        action: Selector?,
        target: AnyObject?,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        if let action {
            item.action = action
        }
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let symbolImage = image.withSymbolConfiguration(config)
            symbolImage?.isTemplate = true
            item.image = symbolImage
        }
        return item
    }

    /// 为统计行等菜单项配置 template 图标。
    static func templateSymbolImage(_ symbol: String) -> NSImage? {
        guard let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) else { return nil }
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let symbolImage = image.withSymbolConfiguration(config)
        symbolImage?.isTemplate = true
        return symbolImage
    }
}

// MARK: - Overlay

private final class ChromeOverlayView: NSView {
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor.black.withAlphaComponent(0.28).cgColor
            : NSColor.black.withAlphaComponent(0.02).cgColor
    }
}
