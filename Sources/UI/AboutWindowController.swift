import AppKit
import QuartzCore

/// 关于窗口 — 明暗自适应
class AboutWindowController: NSWindowController {

    private var keyMonitor: Any?

    init() {
        let panel = AppPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.aboutTitle
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.center()
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        super.init(window: panel)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // 毛玻璃底（跟随系统主题）
        let blur = NSVisualEffectView(frame: contentView.bounds)
        blur.material = .windowBackground
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 12
        blur.layer?.masksToBounds = true
        blur.autoresizingMask = [.width, .height]
        contentView.addSubview(blur)

        // 动态叠加层（亮色几乎透明，暗色加深）
        let overlay = ThemeOverlayView(frame: blur.bounds)
        overlay.autoresizingMask = [.width, .height]
        blur.addSubview(overlay)

        // 顶部 jade 光带
        let topGlow = NSView()
        topGlow.wantsLayer = true
        topGlow.layer?.backgroundColor = ThemeColor.accent.withAlphaComponent(0.18).cgColor
        topGlow.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(topGlow)

        // App Icon
        let iconView = NSImageView()
        if let appIcon = NSImage(named: "AppIcon") {
            iconView.image = appIcon
        } else {
            let cfg = NSImage.SymbolConfiguration(pointSize: 44, weight: .medium)
            iconView.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg)
            iconView.contentTintColor = ThemeColor.accent
        }
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 14
        iconView.layer?.masksToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(iconView)

        // App name
        let nameLabel = NSTextField(labelWithString: "EyeGuard")
        nameLabel.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .labelColor
        nameLabel.alignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(nameLabel)

        // 副标题
        let taglineLabel = NSTextField(labelWithString: "护眼卫士")
        taglineLabel.font = NSFont.systemFont(ofSize: 12, weight: .light)
        taglineLabel.textColor = .secondaryLabelColor
        taglineLabel.alignment = .center
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(taglineLabel)

        // Version badge
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let versionBadge = VersionBadgeView(version: version)
        versionBadge.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(versionBadge)

        // Description
        let descLabel = NSTextField(wrappingLabelWithString: "Work 30 min · Rest 5 min\nGuard your eyes with timed, mindful breaks.")
        descLabel.font = NSFont.systemFont(ofSize: 12, weight: .light)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(descLabel)

        // Divider
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(divider)

        // GitHub link
        let githubBtn = makeLinkButton(title: "github.com/lyloou/eyeguard", action: #selector(openGitHub))
        blur.addSubview(githubBtn)

        NSLayoutConstraint.activate([
            topGlow.topAnchor.constraint(equalTo: blur.topAnchor),
            topGlow.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            topGlow.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            topGlow.heightAnchor.constraint(equalToConstant: 3),

            iconView.topAnchor.constraint(equalTo: blur.topAnchor, constant: 32),
            iconView.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: blur.centerXAnchor),

            taglineLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            taglineLabel.centerXAnchor.constraint(equalTo: blur.centerXAnchor),

            versionBadge.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 10),
            versionBadge.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
            versionBadge.heightAnchor.constraint(equalToConstant: 20),

            descLabel.topAnchor.constraint(equalTo: versionBadge.bottomAnchor, constant: 14),
            descLabel.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 30),
            descLabel.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -30),

            divider.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            githubBtn.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 10),
            githubBtn.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
            githubBtn.bottomAnchor.constraint(equalTo: blur.bottomAnchor, constant: -20),
        ])
    }

    private func makeLinkButton(title: String, action: Selector) -> NSButton {
        let btn = NSButton(title: "", target: self, action: action)
        btn.isBordered = false
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: ThemeColor.accent.withAlphaComponent(0.75),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        btn.attributedTitle = NSAttributedString(string: title, attributes: attrs)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/lyloou/eyeguard") {
            NSWorkspace.shared.open(url)
        }
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func windowWillClose(_ notification: Notification) {
        removeKeyMonitor()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains(.command) else { return event }
            switch event.keyCode {
            case 13: self?.window?.close(); return nil  // ⌘W
            case 12: NSApp.terminate(nil);  return nil  // ⌘Q
            default: return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

// MARK: - Theme overlay (dark mode darkens, light mode leaves transparent)

private class ThemeOverlayView: NSView {
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor.black.withAlphaComponent(0.28).cgColor
            : NSColor.black.withAlphaComponent(0.02).cgColor
    }
}

// MARK: - Version Badge

private class VersionBadgeView: NSView {

    init(version: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 4

        let label = NSTextField(labelWithString: "v\(version)")
        label.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        label.textColor = ThemeColor.accent
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = ThemeColor.accentSubtle.cgColor
        layer?.borderColor     = ThemeColor.accent.withAlphaComponent(0.3).cgColor
        layer?.borderWidth     = 0.5
    }

    required init?(coder: NSCoder) { fatalError() }
}

