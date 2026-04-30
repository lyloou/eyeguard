import AppKit

// MARK: - 单例检测
let lockPath = "/tmp/eyeguard.lock"
if FileManager.default.fileExists(atPath: lockPath) {
    print("EyeGuard 已运行中，退出。")
    exit(0)
}

// 创建锁文件
FileManager.default.createFile(atPath: lockPath, contents: nil)
defer {
    try? FileManager.default.removeItem(atPath: lockPath)
}

// 手动启动 NSApplication
let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // 隐藏 Dock 图标

let delegate = AppDelegate()
app.delegate = delegate

app.run()
