import AppKit

/// 锁屏监控（锁屏暂停 / 解锁恢复）
class LockScreenMonitor {

    private var workspaceNotificationObserver: NSObjectProtocol?
    private var distributedNotificationObserver: NSObjectProtocol?

    var onLock: (() -> Void)?
    var onUnlock: (() -> Void)?

    init() {
        start()
    }

    deinit {
        stop()
    }

    func start() {
        let center = NSWorkspace.shared.notificationCenter

        // 锁屏
        workspaceNotificationObserver = center.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onLock?()
        }

        // 解锁（通过 distributed notification）
        distributedNotificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onUnlock?()
        }
    }

    func stop() {
        if let obs = workspaceNotificationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            workspaceNotificationObserver = nil
        }
        if let obs = distributedNotificationObserver {
            DistributedNotificationCenter.default().removeObserver(obs)
            distributedNotificationObserver = nil
        }
    }
}
