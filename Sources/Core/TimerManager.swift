import AppKit

/// 定时器核心管理器
class TimerManager {

    // MARK: - Properties

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.eyeguard.timer", qos: .userInteractive)

    private(set) var state: EyeState = .idle
    private var remainingSeconds: Int = 0        // 当前状态剩余秒数
    private var frozenSeconds: Int = 0           // 冻结时的值（.paused 时用）

    private weak var statusBarController: StatusBarController?
    private var restWindowController: RestWindowController?

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
        }
        updateUI()
    }

    func skipRest() {
        guard state == .resting else { return }
        closeRestWindow()
        startWorking()
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
        remainingSeconds = Settings.shared.workDuration
        state = .working
        startTimer()
        updateUI()
        SoundManager.shared.playWorkStart()
    }

    private func startResting() {
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
        restWindowController = RestWindowController(manager: self)
        restWindowController?.show()
    }

    private func closeRestWindow() {
        restWindowController?.close()
        restWindowController = nil
    }

    /// 休息弹窗中用户按 Space/ESC 或点跳过
    func dismissRestWindow() {
        let elapsedRest = Settings.shared.restDuration - remainingSeconds
        closeRestWindow()
        NotificationManager.shared.notifyRestEnd()
        SoundManager.shared.playRestEnd()
        StatsManager.shared.recordRestSeconds(elapsedRest)
        startWorking()
    }

    /// 休息计时耗尽，用户还未按键
    func restTimerExpired() {
        closeRestWindow()
        NotificationManager.shared.notifyRestEnd()
        SoundManager.shared.playRestEnd()
        StatsManager.shared.recordRestSeconds(Settings.shared.restDuration)
        startWorking()
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
            return "护眼卫士"
        case .working:
            return "工作中 \(formattedTime)"
        case .paused(let seconds):
            let m = seconds / 60
            let s = seconds % 60
            return "已暂停 \(String(format: "%02d:%02d", m, s))"
        case .resting:
            return "休息中 \(formattedTime)"
        }
    }
}
