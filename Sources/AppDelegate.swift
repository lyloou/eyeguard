import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private(set) var timerManager: TimerManager!
    private var lockScreenMonitor: LockScreenMonitor!
    private var socketBridge: SocketBridge!
    private var notificationManager: NotificationManager!
    private var hotkeyManager: HotkeyManager!
    private var onboardingWindowController: OnboardingWindowController?
    private var aboutWindowController: AboutWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()

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

        // 初始化全局快捷键
        hotkeyManager = HotkeyManager.shared
        hotkeyManager.register()

        // 初始化定时器管理器
        timerManager = TimerManager(statusBarController: statusBarController)
        statusBarController.timerManager = timerManager

        // 首次启动引导
        if !Settings.shared.hasLaunchedBefore {
            Settings.shared.hasLaunchedBefore = true
            onboardingWindowController = OnboardingWindowController()
            onboardingWindowController?.show()
        }

        // 监听显示关于窗口通知
        NotificationCenter.default.addObserver(
            forName: .showAboutWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.aboutWindowController == nil {
                self?.aboutWindowController = AboutWindowController()
            }
            self?.aboutWindowController?.show()
        }

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

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App 菜单（macOS 规范：第一个菜单项作为 App 菜单，标题被系统替换为 App 名）
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(
            title: "Quit EyeGuard",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // File 菜单：Cmd+W → performClose（关闭当前 key window）
        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(
            title: "Close",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        ))

        NSApp.mainMenu = mainMenu
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
        lockScreenMonitor.stop()
    }
}
