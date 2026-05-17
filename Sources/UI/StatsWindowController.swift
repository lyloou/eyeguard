import AppKit

/// 运行统计窗口：今日摘要卡片、区间选择与工作/休息双折线图。
class StatsWindowController: NSWindowController, NSWindowDelegate {

    private var keyMonitor: Any?
    private var workMetricCard: StatsMetricCardView!
    private var restMetricCard: StatsMetricCardView!
    private var roundsMetricCard: StatsMetricCardView!
    private var rangeSummaryLabel: NSTextField!
    private var chartView: DualLineChartView!
    private var presetControl: NSSegmentedControl!
    private var fromDatePicker: NSDatePicker!
    private var toDatePicker: NSDatePicker!
    private var rangeWarningLabel: NSTextField!
    private var titleTopConstraint: NSLayoutConstraint!

    private var selectedPresetDays: Int = 7

    /// 标题距标题栏安全区底部的额外间距。
    private let titleTopPadding: CGFloat = 10
    /// 标题左侧留白，避开红黄绿交通灯区域（约 3 个按钮 + 边距）。
    private let titleLeadingInset: CGFloat = 78

    private let calendar = Calendar.current
    private let axisDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init() {
        let panel = AppPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.statsTitle
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.center()
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        super.init(window: panel)
        window?.delegate = self
        setupUI()
        applyPreset(days: 7)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let blur = NSVisualEffectView(frame: contentView.bounds)
        blur.material = .windowBackground
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 12
        blur.layer?.masksToBounds = true
        blur.autoresizingMask = [.width, .height]
        contentView.addSubview(blur)

        let overlay = StatsThemeOverlayView(frame: blur.bounds)
        overlay.autoresizingMask = [.width, .height]
        blur.addSubview(overlay)

        let topGlow = NSView()
        topGlow.wantsLayer = true
        topGlow.layer?.backgroundColor = ThemeColor.accent.withAlphaComponent(0.16).cgColor
        topGlow.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(topGlow)

        let titleLabel = NSTextField(labelWithString: L10n.statsTitle)
        titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(titleLabel)

        let metricsRow = NSStackView()
        metricsRow.orientation = .horizontal
        metricsRow.distribution = .fillEqually
        metricsRow.spacing = 10
        metricsRow.translatesAutoresizingMaskIntoConstraints = false

        workMetricCard = StatsMetricCardView(
            title: L10n.statsMetricWork,
            accent: ThemeColor.accent
        )
        restMetricCard = StatsMetricCardView(
            title: L10n.statsMetricRest,
            accent: ThemeColor.chartRest
        )
        roundsMetricCard = StatsMetricCardView(
            title: L10n.statsMetricRounds,
            accent: ThemeColor.accent.withAlphaComponent(0.75)
        )
        metricsRow.addArrangedSubview(workMetricCard)
        metricsRow.addArrangedSubview(restMetricCard)
        metricsRow.addArrangedSubview(roundsMetricCard)
        blur.addSubview(metricsRow)

        let rangeCard = StatsSectionCardView()
        rangeCard.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(rangeCard)

        let rangeTitle = NSTextField(labelWithString: L10n.statsRangeTitle)
        rangeTitle.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        rangeTitle.textColor = .secondaryLabelColor
        rangeTitle.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.contentView.addSubview(rangeTitle)

        presetControl = NSSegmentedControl(labels: [
            L10n.statsPreset7,
            L10n.statsPreset14,
            L10n.statsPreset30,
        ], trackingMode: .selectOne, target: self, action: #selector(presetChanged(_:)))
        presetControl.selectedSegment = 0
        presetControl.segmentDistribution = .fillEqually
        presetControl.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.contentView.addSubview(presetControl)

        let fromLabel = NSTextField(labelWithString: L10n.statsFrom)
        fromLabel.font = NSFont.systemFont(ofSize: 12)
        fromLabel.textColor = .secondaryLabelColor
        fromLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.contentView.addSubview(fromLabel)

        fromDatePicker = makeDatePicker(action: #selector(customRangeChanged(_:)))
        rangeCard.contentView.addSubview(fromDatePicker)

        let toLabel = NSTextField(labelWithString: L10n.statsTo)
        toLabel.font = NSFont.systemFont(ofSize: 12)
        toLabel.textColor = .secondaryLabelColor
        toLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.contentView.addSubview(toLabel)

        toDatePicker = makeDatePicker(action: #selector(customRangeChanged(_:)))
        rangeCard.contentView.addSubview(toDatePicker)

        rangeWarningLabel = NSTextField(labelWithString: "")
        rangeWarningLabel.font = NSFont.systemFont(ofSize: 11)
        rangeWarningLabel.textColor = .systemRed
        rangeWarningLabel.isHidden = true
        rangeWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.contentView.addSubview(rangeWarningLabel)

        let rangeContent = rangeCard.contentView
        NSLayoutConstraint.activate([
            rangeTitle.topAnchor.constraint(equalTo: rangeContent.topAnchor, constant: 14),
            rangeTitle.leadingAnchor.constraint(equalTo: rangeContent.leadingAnchor, constant: 14),

            presetControl.topAnchor.constraint(equalTo: rangeTitle.bottomAnchor, constant: 10),
            presetControl.leadingAnchor.constraint(equalTo: rangeContent.leadingAnchor, constant: 14),
            presetControl.trailingAnchor.constraint(equalTo: rangeContent.trailingAnchor, constant: -14),

            fromLabel.topAnchor.constraint(equalTo: presetControl.bottomAnchor, constant: 12),
            fromLabel.leadingAnchor.constraint(equalTo: rangeContent.leadingAnchor, constant: 14),

            fromDatePicker.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor),
            fromDatePicker.leadingAnchor.constraint(equalTo: fromLabel.trailingAnchor, constant: 8),

            toLabel.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor),
            toLabel.leadingAnchor.constraint(equalTo: fromDatePicker.trailingAnchor, constant: 16),

            toDatePicker.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor),
            toDatePicker.leadingAnchor.constraint(equalTo: toLabel.trailingAnchor, constant: 8),
            toDatePicker.trailingAnchor.constraint(lessThanOrEqualTo: rangeContent.trailingAnchor, constant: -14),

            rangeWarningLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 8),
            rangeWarningLabel.leadingAnchor.constraint(equalTo: rangeContent.leadingAnchor, constant: 14),
            rangeWarningLabel.bottomAnchor.constraint(equalTo: rangeContent.bottomAnchor, constant: -12),
        ])

        chartView = DualLineChartView()
        chartView.wantsLayer = true
        chartView.layer?.cornerRadius = 12
        chartView.layer?.backgroundColor = ThemeColor.cardBackground.cgColor
        chartView.layer?.borderColor = ThemeColor.cardBorder.cgColor
        chartView.layer?.borderWidth = 0.5
        chartView.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(chartView)

        let footerCard = StatsSectionCardView()
        footerCard.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(footerCard)

        rangeSummaryLabel = NSTextField(wrappingLabelWithString: "")
        rangeSummaryLabel.font = NSFont.systemFont(ofSize: 12)
        rangeSummaryLabel.textColor = .secondaryLabelColor
        rangeSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        footerCard.contentView.addSubview(rangeSummaryLabel)

        let footerContent = footerCard.contentView
        NSLayoutConstraint.activate([
            rangeSummaryLabel.topAnchor.constraint(equalTo: footerContent.topAnchor, constant: 12),
            rangeSummaryLabel.leadingAnchor.constraint(equalTo: footerContent.leadingAnchor, constant: 14),
            rangeSummaryLabel.trailingAnchor.constraint(equalTo: footerContent.trailingAnchor, constant: -14),
            rangeSummaryLabel.bottomAnchor.constraint(equalTo: footerContent.bottomAnchor, constant: -12),
        ])

        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: blur.topAnchor, constant: 52)

        NSLayoutConstraint.activate([
            topGlow.topAnchor.constraint(equalTo: blur.topAnchor),
            topGlow.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            topGlow.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            topGlow.heightAnchor.constraint(equalToConstant: 3),

            titleTopConstraint,
            titleLabel.leadingAnchor.constraint(
                equalTo: blur.leadingAnchor,
                constant: titleLeadingInset
            ),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blur.trailingAnchor, constant: -20),

            metricsRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            metricsRow.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            metricsRow.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),
            metricsRow.heightAnchor.constraint(equalToConstant: 76),

            rangeCard.topAnchor.constraint(equalTo: metricsRow.bottomAnchor, constant: 16),
            rangeCard.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            rangeCard.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),

            chartView.topAnchor.constraint(equalTo: rangeCard.bottomAnchor, constant: 14),
            chartView.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            chartView.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),
            chartView.heightAnchor.constraint(equalToConstant: 300),

            footerCard.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 12),
            footerCard.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 20),
            footerCard.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -20),
            footerCard.bottomAnchor.constraint(lessThanOrEqualTo: blur.bottomAnchor, constant: -18),
        ])

        applyLocalization()
    }

    /// 创建仅日期的选择器。
    private func makeDatePicker(action: Selector) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = .yearMonthDay
        picker.datePickerMode = .single
        picker.target = self
        picker.action = action
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }

    // MARK: - Data

    /// 设置区间起止日。
    private func setRange(start: Date, end: Date) {
        fromDatePicker.dateValue = calendar.startOfDay(for: start)
        toDatePicker.dateValue = calendar.startOfDay(for: end)
    }

    /// 按当前区间刷新指标卡、折线图与区间摘要。
    private func reloadData() {
        let from = calendar.startOfDay(for: fromDatePicker.dateValue)
        let to = calendar.startOfDay(for: toDatePicker.dateValue)
        let dayCount = calendar.dateComponents([.day], from: from, to: to).day.map { $0 + 1 } ?? 0

        workMetricCard.setValue(
            "\(StatsManager.shared.totalWorkMinutesToday)",
            unit: L10n.statsMetricUnitMin
        )
        restMetricCard.setValue(
            "\(StatsManager.shared.totalRestMinutesToday)",
            unit: L10n.statsMetricUnitMin
        )
        roundsMetricCard.setValue(
            "\(StatsManager.shared.roundsCompletedToday)",
            unit: L10n.statsMetricUnitRound
        )

        if from > to {
            rangeWarningLabel.stringValue = L10n.statsInvalidRange
            rangeWarningLabel.isHidden = false
            chartView.points = []
            rangeSummaryLabel.stringValue = ""
            return
        }

        if dayCount > StatsManager.maxCustomRangeDays {
            rangeWarningLabel.stringValue = L10n.statsRangeTooLong(StatsManager.maxCustomRangeDays)
            rangeWarningLabel.isHidden = false
            chartView.points = []
            rangeSummaryLabel.stringValue = ""
            return
        }

        rangeWarningLabel.isHidden = true

        let stats = StatsManager.shared.dailyStats(from: from, to: to)
        let totals = StatsManager.shared.totals(in: stats)
        let daySpan = stats.count

        if daySpan > 0 {
            rangeSummaryLabel.stringValue = L10n.statsRangeSummary(
                days: daySpan,
                work: totals.workMinutes,
                rest: totals.restMinutes,
                rounds: totals.rounds,
                avgWork: totals.workMinutes / daySpan,
                avgRest: totals.restMinutes / daySpan
            )
        } else {
            rangeSummaryLabel.stringValue = ""
        }

        chartView.workLegendTitle = L10n.statsLegendWork
        chartView.restLegendTitle = L10n.statsLegendRest
        chartView.emptyMessage = L10n.statsChartEmpty
        chartView.yAxisUnit = L10n.statsYAxisUnit

        chartView.points = stats.map { day in
            let label: String
            if let date = dateFromString(day.date) {
                label = axisDateFormatter.string(from: date)
            } else {
                label = day.date
            }
            return DualLineChartPoint(
                label: label,
                workMinutes: Double(day.workMinutes),
                restMinutes: Double(day.restMinutes)
            )
        }
    }

    /// 将 `yyyy-MM-dd` 解析为日期。
    private func dateFromString(_ value: String?) -> Date? {
        guard let value else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: value)
    }

    /// 应用快捷区间预设。
    private func applyPreset(days: Int) {
        selectedPresetDays = days
        switch days {
        case 14: presetControl.selectedSegment = 1
        case 30: presetControl.selectedSegment = 2
        default: presetControl.selectedSegment = 0
        }
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end
        setRange(start: start, end: end)
        reloadData()
    }

    // MARK: - Actions

    @objc private func presetChanged(_ sender: NSSegmentedControl) {
        let days: Int
        switch sender.selectedSegment {
        case 1: days = 14
        case 2: days = 30
        default: days = 7
        }
        applyPreset(days: days)
    }

    @objc private func customRangeChanged(_ sender: NSDatePicker) {
        _ = sender
        for segment in 0..<presetControl.segmentCount {
            presetControl.setSelected(false, forSegment: segment)
        }
        reloadData()
    }

    // MARK: - Window

    /// 语言切换后刷新文案。
    func applyLocalization() {
        window?.title = L10n.statsTitle
        presetControl.setLabel(L10n.statsPreset7, forSegment: 0)
        presetControl.setLabel(L10n.statsPreset14, forSegment: 1)
        presetControl.setLabel(L10n.statsPreset30, forSegment: 2)
        workMetricCard.setTitle(L10n.statsMetricWork)
        restMetricCard.setTitle(L10n.statsMetricRest)
        roundsMetricCard.setTitle(L10n.statsMetricRounds)
        reloadData()
    }

    /// 根据窗口 `contentLayoutRect` 更新标题与交通灯的安全间距。
    private func updateTitleBarInsets() {
        guard let window = window else { return }
        window.layoutIfNeeded()
        let contentHeight = window.contentView?.bounds.height ?? 0
        let layoutHeight = window.contentLayoutRect.height
        let titleBarHeight = contentHeight > 0 ? contentHeight - layoutHeight : 28
        titleTopConstraint.constant = max(titleBarHeight, 28) + titleTopPadding
    }

    /// 显示统计窗口并安装快捷键监听。
    func show() {
        applyPreset(days: selectedPresetDays)
        window?.makeKeyAndOrderFront(nil)
        updateTitleBarInsets()
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func windowDidResize(_ notification: Notification) {
        updateTitleBarInsets()
    }

    func windowWillClose(_ notification: Notification) {
        removeKeyMonitor()
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

// MARK: - Metric card

/// 今日单项指标卡片。
private final class StatsMetricCardView: NSView {

    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "0")
    private let unitLabel = NSTextField(labelWithString: "")
    private let accentBar = NSView()

    init(title: String, accent: NSColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = ThemeColor.cardBackground.cgColor
        layer?.borderColor = ThemeColor.cardBorder.cgColor
        layer?.borderWidth = 0.5

        accentBar.wantsLayer = true
        accentBar.layer?.backgroundColor = accent.cgColor
        accentBar.layer?.cornerRadius = 1.5
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .semibold)
        valueLabel.textColor = .labelColor
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        unitLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        unitLabel.textColor = .tertiaryLabelColor
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(unitLabel)

        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            accentBar.widthAnchor.constraint(equalToConstant: 3),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            unitLabel.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 4),
            unitLabel.lastBaselineAnchor.constraint(equalTo: valueLabel.lastBaselineAnchor),
            unitLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// 更新标题文案。
    func setTitle(_ title: String) {
        titleLabel.stringValue = title
    }

    /// 更新数值与单位。
    func setValue(_ value: String, unit: String) {
        valueLabel.stringValue = value
        unitLabel.stringValue = unit
    }
}

// MARK: - Section card

/// 带圆角与边框的分组容器。
private final class StatsSectionCardView: NSView {

    let contentView = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 10
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

// MARK: - Overlay

private class StatsThemeOverlayView: NSView {
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor.black.withAlphaComponent(0.28).cgColor
            : NSColor.black.withAlphaComponent(0.02).cgColor
    }
}
