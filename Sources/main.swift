import AppKit

// MARK: - 单例检测（flock 智能检测）

let lockPath = "/tmp/eyeguard.lock"
let lockFileHandle = open(lockPath, O_CREAT | O_RDWR, 0o644)
if lockFileHandle < 0 {
    print("EyeGuard: 无法创建锁文件，退出。")
    exit(1)
}
defer { close(lockFileHandle) }

// NONBLOCK: 如果已锁直接退出（快速检测）
let flockResult = flock(lockFileHandle, LOCK_EX | LOCK_NB)
if flockResult != 0 {
    // 锁被占用 — 进一步验证进程是否真实存活
    if isProcessRunning(pidFromLockFile()) {
        print("EyeGuard 已运行中，退出。")
        exit(0)
    }
    // 进程已死但锁残留，清理后重新获取
    flock(lockFileHandle, LOCK_UN)
    unlink(lockPath)
    let fd2 = open(lockPath, O_CREAT | O_RDWR, 0o644)
    if fd2 < 0 || flock(fd2, LOCK_EX | LOCK_NB) != 0 {
        print("EyeGuard 已运行中，退出。")
        exit(0)
    }
    _ = fd2
}

// 写入 PID 到锁文件
func pidFromLockFile() -> pid_t? {
    guard let data = try? String(contentsOfFile: lockPath, encoding: .utf8),
          let pid = pid_t(data.trimmingCharacters(in: .whitespacesAndNewlines)) else {
        return nil
    }
    return pid
}

func isProcessRunning(_ pid: pid_t?) -> Bool {
    guard let pid = pid else { return false }
    return kill(pid, 0) == 0
}

// 写入当前 PID
let pidString = "\(getpid())\n"
unlink(lockPath)
_ = try? pidString.write(toFile: lockPath, atomically: true, encoding: .utf8)

defer { try? FileManager.default.removeItem(atPath: lockPath) }

// 手动启动 NSApplication
let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // 隐藏 Dock 图标

let delegate = AppDelegate()
app.delegate = delegate

app.run()
