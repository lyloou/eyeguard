import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private(set) var timerManager: TimerManager!
    private var lockScreenMonitor: LockScreenMonitor!
    private var socketBridge: SocketBridge!
    private var notificationManager: NotificationManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化设置
        Settings.shared.registerDefaults()

        // 初始化状态栏
        statusBarController = StatusBarController()

        // 初始化锁屏监控
        lockScreenMonitor = LockScreenMonitor()

        // 初始化通知管理器（请求授权）
        notificationManager = NotificationManager.shared
        notificationManager.requestAuthorization { granted in
            if granted {
                print("NotificationManager: 通知授权已授予")
            } else {
                print("NotificationManager: 通知授权被拒绝")
            }
        }

        // 初始化 Socket 桥接（接收 CLI 命令）
        socketBridge = SocketBridge()

        // 初始化定时器管理器
        timerManager = TimerManager(statusBarController: statusBarController)
        statusBarController.timerManager = timerManager

        // 启动后自动开始工作计时
        timerManager.start()

        // 锁屏暂停逻辑
        lockScreenMonitor.onLock = { [weak self] in
            self?.timerManager.pauseOnLock()
        }
        lockScreenMonitor.onUnlock = { [weak self] in
            self?.timerManager.resumeOnUnlock()
        }

        print("EyeGuard 已启动")
    }

    func applicationWillTerminate(_ notification: Notification) {
        lockScreenMonitor.stop()
    }
}
