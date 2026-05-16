import AppKit

/// 定时器核心管理器
class TimerManager {

    // MARK: - Properties

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.eyeguard.timer", qos: .userInteractive)

    private(set) var state: EyeState = .idle
    private(set) var remainingSeconds: Int = 0        // 当前状态剩余秒数（外部只读）
    private var frozenSeconds: Int = 0           // 冻结时的值（.paused 时用）

    private weak var statusBarController: StatusBarController?
    private var restWindowController: RestWindowController?

    /// 等待键鼠活动时用于轮询系统空闲时间的定时器
    private var activityPollTimer: Timer?
    /// 进入 `.awaitingActivity` 时记录的空闲秒数基线
    private var activityBaselineIdle: TimeInterval = 0

    var onStateChanged: ((EyeState) -> Void)?

    // MARK: - Init

    init(statusBarController: StatusBarController) {
        self.statusBarController = statusBarController
    }

    // MARK: - Public Actions

    func start() {
        guard state == .idle else { return }
        startWorking()
    }

    func pause() {
        guard state == .working else { return }
        frozenSeconds = remainingSeconds
        state = .paused(remaining: frozenSeconds)
        stopTimer()
        updateUI()
    }

    func resume() {
        guard case .paused(let seconds) = state else { return }
        remainingSeconds = seconds
        state = .working
        startTimer()
        updateUI()
    }

    func reset() {
        stopAwaitingActivity()
        stopTimer()
        switch state {
        case .idle:
            return
        case .working:
            remainingSeconds = Settings.shared.workDuration
        case .paused:
            remainingSeconds = frozenSeconds
        case .resting:
            remainingSeconds = Settings.shared.restDuration
        case .awaitingActivity:
            state = .idle
            remainingSeconds = 0
        }
        updateUI()
    }

    func skipRest() {
        guard state == .resting else { return }
        let elapsedRest = Settings.shared.restDuration - remainingSeconds
        finishRest(elapsedRestSeconds: elapsedRest)
    }

    /// 立即进入休息
    func restNow() {
        switch state {
        case .working:
            stopTimer()
            closeRestWindow()
            startResting()
        case .paused:
            stopTimer()
            closeRestWindow()
            startResting()
        default:
            return
        }
    }

    /// 锁屏触发暂停
    func pauseOnLock() {
        guard Settings.shared.pauseOnLock else { return }
        if case .working = state {
            frozenSeconds = remainingSeconds
            state = .paused(remaining: frozenSeconds)
            stopTimer()
            updateUI()
        }
    }

    /// 解锁触发恢复
    func resumeOnUnlock() {
        guard Settings.shared.pauseOnLock else { return }
        if case .paused = state {
            remainingSeconds = frozenSeconds
            state = .working
            startTimer()
            updateUI()
        }
    }

    // MARK: - Private

    private func startWorking() {
        stopAwaitingActivity()
        remainingSeconds = Settings.shared.workDuration
        state = .working
        startTimer()
        updateUI()
        SoundManager.shared.playWorkStart()
    }

    private func startResting() {
        stopAwaitingActivity()
        remainingSeconds = Settings.shared.restDuration
        state = .resting
        stopTimer()
        updateUI()
        showRestWindow()
        StatsManager.shared.recordRoundCompleted()
        NotificationManager.shared.notifyRestStart(
            workMinutes: Settings.shared.workDuration / 60,
            restMinutes: Settings.shared.restDuration / 60
        )
        SoundManager.shared.playRestStart()
    }

    private func startTimer() {
        stopTimer()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [weak self] in
            self?.tick()
        }
        timer?.resume()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            onTimerZero()
            return
        }
        remainingSeconds -= 1
        updateUI()
    }

    private func onTimerZero() {
        stopTimer()
        if state == .working {
            startResting()
        } else if state == .resting {
            // 等待用户按键，弹窗会处理
        }
    }

    private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusBarController?.updateState(self.state, remaining: self.remainingSeconds)
            self.onStateChanged?(self.state)
        }
    }

    // MARK: - Rest Window

    private func showRestWindow() {
        closeRestWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.restWindowController = RestWindowController(manager: self)
            self.restWindowController?.show()
        }
    }

    private func closeRestWindow() {
        restWindowController?.close()
        restWindowController = nil
    }

    /// 休息弹窗计时器每秒回调，更新状态栏倒计时
    func updateRestRemaining(_ seconds: Int) {
        remainingSeconds = seconds
        updateUI()
    }

    /// 休息弹窗中用户按 Space/ESC 或点跳过
    func dismissRestWindow() {
        let elapsedRest = Settings.shared.restDuration - remainingSeconds
        finishRest(elapsedRestSeconds: elapsedRest)
    }

    /// 休息计时耗尽，用户还未按键
    func restTimerExpired() {
        finishRest(elapsedRestSeconds: Settings.shared.restDuration)
    }

    /// 结束休息：关窗、通知与统计，再按设置决定立即开工或等待键鼠活动。
    private func finishRest(elapsedRestSeconds: Int) {
        closeRestWindow()
        NotificationManager.shared.notifyRestEnd()
        SoundManager.shared.playRestEnd()
        StatsManager.shared.recordRestSeconds(elapsedRestSeconds)
        transitionToWorkAfterRest()
    }

    /// 在休息已结束后进入工作计时，或进入等待活动状态。
    private func transitionToWorkAfterRest() {
        guard Settings.shared.waitForActivityAfterRest else {
            startWorking()
            return
        }
        if UserActivityDetector.hasRecentActivity() {
            startWorking()
            return
        }
        beginAwaitingActivity()
    }

    /// 进入等待键鼠活动状态并启动轮询。
    private func beginAwaitingActivity() {
        stopTimer()
        activityBaselineIdle = UserActivityDetector.combinedIdleSeconds()
        state = .awaitingActivity
        remainingSeconds = Settings.shared.workDuration
        updateUI()
        startActivityPolling()
    }

    /// 每 0.5 秒检查是否出现休息结束后的新键鼠活动。
    private func startActivityPolling() {
        stopActivityPolling()
        activityPollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.pollForActivityAfterRest()
        }
    }

    /// 停止活动轮询并清除基线。
    private func stopAwaitingActivity() {
        stopActivityPolling()
        activityBaselineIdle = 0
    }

    private func stopActivityPolling() {
        activityPollTimer?.invalidate()
        activityPollTimer = nil
    }

    /// 检测到新活动后结束等待并开始工作。
    private func pollForActivityAfterRest() {
        guard state == .awaitingActivity else {
            stopAwaitingActivity()
            return
        }
        guard UserActivityDetector.hasNewActivitySince(baselineIdle: activityBaselineIdle) else {
            return
        }
        startWorking()
    }

    /// 语言切换后刷新休息窗与状态栏展示。
    func refreshLocalizedUI() {
        restWindowController?.applyLocalization()
        updateUI()
    }

    // MARK: - Helpers

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var statusBarText: String {
        switch state {
        case .idle:
            return L10n.appName
        case .working:
            return L10n.statusWorking(formattedTime)
        case .paused(let seconds):
            let m = seconds / 60
            let s = seconds % 60
            return L10n.statusPaused(String(format: "%02d:%02d", m, s))
        case .resting:
            return L10n.statusResting(formattedTime)
        case .awaitingActivity:
            return L10n.statusAwaitingActivity
        }
    }
}
