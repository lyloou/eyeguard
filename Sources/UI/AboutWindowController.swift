import AppKit

/// 关于窗口 — 与设置/统计页统一的毛玻璃卡片风格。
class AboutWindowController: NSWindowController, NSWindowDelegate {

    private var keyMonitor: Any?
    private var titleTopConstraint: NSLayoutConstraint!
    private var headerLabel: NSTextField!
    private var appNameLabel: NSTextField!
    private var descLabel: NSTextField!
    private var versionBadge: AboutVersionBadgeView!

    init() {
        let panel = AppPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.aboutTitle
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        EyeGuardWindowChrome.configure(panel: panel)
        panel.center()
        super.init(window: panel)
        window?.delegate = self
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let blur = EyeGuardWindowChrome.installBackground(on: contentView)
        _ = EyeGuardWindowChrome.addTopGlow(to: blur)

        headerLabel = NSTextField(labelWithString: "")
        headerLabel.lineBreakMode = .byTruncatingTail
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(headerLabel)
        updateHeader()

        let heroCard = AboutHeroCardView()
        heroCard.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(heroCard)

        let iconRing = NSView()
        iconRing.wantsLayer = true
        iconRing.layer?.cornerRadius = 22
        iconRing.layer?.borderWidth = 1.5
        iconRing.layer?.borderColor = ThemeColor.accent.withAlphaComponent(0.35).cgColor
        iconRing.layer?.backgroundColor = ThemeColor.accentSubtle.cgColor
        iconRing.translatesAutoresizingMaskIntoConstraints = false
        heroCard.contentView.addSubview(iconRing)

        let iconView = NSImageView()
        if let appIcon = NSImage(named: NSImage.applicationIconName) ?? NSImage(named: "AppIcon") {
            iconView.image = appIcon
        } else {
            let cfg = NSImage.SymbolConfiguration(pointSize: 40, weight: .medium)
            iconView.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg)
            iconView.contentTintColor = ThemeColor.accent
        }
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 16
        iconView.layer?.masksToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        heroCard.contentView.addSubview(iconView)

        appNameLabel = NSTextField(labelWithString: L10n.appName)
        appNameLabel.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        appNameLabel.textColor = .labelColor
        appNameLabel.alignment = .center
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        heroCard.contentView.addSubview(appNameLabel)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionBadge = AboutVersionBadgeView(version: version)
        versionBadge.translatesAutoresizingMaskIntoConstraints = false
        heroCard.contentView.addSubview(versionBadge)

        descLabel = NSTextField(wrappingLabelWithString: L10n.aboutDescription)
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.maximumNumberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        heroCard.contentView.addSubview(descLabel)

        let linkCard = AboutHeroCardView()
        linkCard.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(linkCard)

        let githubBtn = makeGitHubButton()
        linkCard.contentView.addSubview(githubBtn)

        let hero = heroCard.contentView
        titleTopConstraint = headerLabel.topAnchor.constraint(equalTo: blur.topAnchor, constant: 52)

        NSLayoutConstraint.activate([
            titleTopConstraint,
            headerLabel.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 78),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: blur.trailingAnchor, constant: -20),

            heroCard.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 18),
            heroCard.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            heroCard.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),

            iconRing.topAnchor.constraint(equalTo: hero.topAnchor, constant: 22),
            iconRing.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            iconRing.widthAnchor.constraint(equalToConstant: 88),
            iconRing.heightAnchor.constraint(equalToConstant: 88),

            iconView.centerXAnchor.constraint(equalTo: iconRing.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconRing.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 72),
            iconView.heightAnchor.constraint(equalToConstant: 72),

            appNameLabel.topAnchor.constraint(equalTo: iconRing.bottomAnchor, constant: 14),
            appNameLabel.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            appNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: hero.leadingAnchor, constant: 16),
            appNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: hero.trailingAnchor, constant: -16),

            versionBadge.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 8),
            versionBadge.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            versionBadge.heightAnchor.constraint(equalToConstant: 22),

            descLabel.topAnchor.constraint(equalTo: versionBadge.bottomAnchor, constant: 14),
            descLabel.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 20),
            descLabel.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -20),
            descLabel.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -22),

            linkCard.topAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: 12),
            linkCard.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            linkCard.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),
            linkCard.bottomAnchor.constraint(lessThanOrEqualTo: blur.bottomAnchor, constant: -18),

            githubBtn.topAnchor.constraint(equalTo: linkCard.contentView.topAnchor, constant: 10),
            githubBtn.bottomAnchor.constraint(equalTo: linkCard.contentView.bottomAnchor, constant: -10),
            githubBtn.centerXAnchor.constraint(equalTo: linkCard.contentView.centerXAnchor),
        ])
    }

    /// 刷新顶栏「标题 · 副标题」富文本。
    private func updateHeader() {
        headerLabel?.attributedStringValue = EyeGuardWindowChrome.attributedHeader(
            title: L10n.aboutTitle,
            subtitle: L10n.aboutTagline
        )
    }

    /// 创建 GitHub 链接按钮（图标 + 文字）。
    private func makeGitHubButton() -> NSButton {
        let btn = NSButton(title: "", target: self, action: #selector(openGitHub))
        btn.isBordered = false
        btn.translatesAutoresizingMaskIntoConstraints = false

        let title = "github.com/lyloou/eyeguard"
        btn.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: ThemeColor.accent,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]
        )
        if let icon = NSImage(systemSymbolName: "link", accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            btn.image = icon.withSymbolConfiguration(config)
            btn.imagePosition = .imageLeading
            btn.imageHugsTitle = true
        }
        return btn
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/lyloou/eyeguard") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 语言切换后刷新关于窗口文案。
    func applyLocalization() {
        window?.title = L10n.aboutTitle
        updateHeader()
        appNameLabel?.stringValue = L10n.appName
        descLabel?.stringValue = L10n.aboutDescription
    }

    func show() {
        updateTitleBarInsets()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func windowWillClose(_ notification: Notification) {
        removeKeyMonitor()
    }

    func windowDidResize(_ notification: Notification) {
        updateTitleBarInsets()
    }

    private func updateTitleBarInsets() {
        titleTopConstraint?.constant = EyeGuardWindowChrome.titleTopInset(for: window)
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains(.command) else { return event }
            switch event.keyCode {
            case 13: self?.window?.close(); return nil
            case 12: NSApp.terminate(nil); return nil
            default: return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

// MARK: - Hero card

/// 关于页圆角卡片容器。
private final class AboutHeroCardView: NSView {

    let contentView = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = ThemeColor.cardBackground.cgColor
        layer?.borderColor = ThemeColor.cardBorder.cgColor
        layer?.borderWidth = 0.5

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Version badge

/// 版本号徽章。
private final class AboutVersionBadgeView: NSView {

    private let label = NSTextField(labelWithString: "")

    init(version: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6

        label.stringValue = "v\(version)"
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        label.textColor = ThemeColor.accent
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = ThemeColor.accentSubtle.cgColor
        layer?.borderColor = ThemeColor.accent.withAlphaComponent(0.28).cgColor
        layer?.borderWidth = 0.5
    }
}
