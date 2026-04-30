import AppKit

/// 首次启动引导窗口
class OnboardingWindowController: NSWindowController {

    private var currentStep = 0
    private let steps = [
        (L10n.guideStep1, "step1"),
        (L10n.guideStep2, "step2"),
        (L10n.guideStep3, "step3")
    ]

    private var iconView: NSImageView!
    private var stepLabel: NSTextField!
    private var dotsView: NSStackView!
    private var nextButton: NSButton!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.guideTitle
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupUI()
        showStep(0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        // SF Symbol icon
        iconView = NSImageView(frame: NSRect(x: 0, y: 0, width: 340, height: 80))
        iconView.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        iconView.contentTintColor = NSColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        // Step label
        stepLabel = NSTextField(wrappingLabelWithString: "")
        stepLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        stepLabel.textColor = .labelColor
        stepLabel.alignment = .center
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepLabel)

        // Page dots
        dotsView = NSStackView()
        dotsView.orientation = .horizontal
        dotsView.spacing = 8
        dotsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dotsView)

        for _ in steps {
            let dot = NSView(frame: NSRect(x: 0, y: 0, width: 8, height: 8))
            dot.wantsLayer = true
            dot.layer?.backgroundColor = NSColor.systemGray.cgColor
            dot.layer?.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            dotsView.addArrangedSubview(dot)
        }

        // Buttons
        let skipButton = NSButton(title: "Skip", target: self, action: #selector(skipClicked))
        skipButton.bezelStyle = .rounded
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skipButton)

        nextButton = NSButton(title: "Next →", target: self, action: #selector(nextClicked))
        nextButton.bezelStyle = .rounded
        nextButton.keyEquivalent = "\r"
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),

            stepLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            stepLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            dotsView.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 24),
            dotsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nextButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),

            skipButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            skipButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
        ])
    }

    private func showStep(_ index: Int) {
        currentStep = index
        stepLabel.stringValue = steps[index].0

        // Update dots
        for (i, view) in dotsView.arrangedSubviews.enumerated() {
            view.layer?.backgroundColor = (i == index ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor)
        }

        nextButton.title = index == steps.count - 1 ? L10n.guideGotIt : "Next →"
    }

    @objc private func nextClicked() {
        if currentStep < steps.count - 1 {
            showStep(currentStep + 1)
        } else {
            close()
        }
    }

    @objc private func skipClicked() {
        close()
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
