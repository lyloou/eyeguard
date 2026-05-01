import Foundation
import AppKit

/// Unix Domain Socket 命令监听器，接收 CLI 命令
class SocketBridge {

    static let socketPath = "/tmp/eyeguard.sock"

    private let queue = DispatchQueue(label: "com.eyeguard.socket", qos: .userInteractive)
    private var listenerThread: Thread?

    init?() {
        startSocketListener()
    }

    deinit {
        stopSocketListener()
    }

    private func startSocketListener() {
        listenerThread = Thread { [weak self] in
            self?.runSocketServer()
        }
        listenerThread?.name = "SocketBridge"
        listenerThread?.start()
    }

    private func stopSocketListener() {
        listenerThread?.cancel()
        listenerThread = nil
        try? FileManager.default.removeItem(atPath: Self.socketPath)
    }

    private func runSocketServer() {
        let fd = socket(PF_LOCAL, SOCK_STREAM, 0)
        guard fd >= 0 else {
            print("SocketBridge: socket() failed")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_LOCAL)
        let path = Self.socketPath
        path.withCString { ptr in
            withUnsafeMutableBytes(of: &addr.sun_path) { dest in
                strncpy(dest.baseAddress?.assumingMemoryBound(to: CChar.self), ptr, dest.count)
            }
        }

        unlink(path)

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            bind(fd, UnsafePointer<sockaddr>(OpaquePointer(ptr)), socklen_t(MemoryLayout<sockaddr_un>.size))
        }

        guard bindResult == 0 else {
            print("SocketBridge: bind() failed")
            close(fd)
            return
        }

        listen(fd, 5)
        print("SocketBridge 已启动，监听 \(path)")

        while !Thread.current.isCancelled {
            var clientAddr = sockaddr_un()
            var addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let clientFD: Int32 = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                accept(fd, UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: sockaddr.self), &addrLen)
            }

            guard clientFD >= 0 else {
                usleep(100_000) // 100ms
                continue
            }

            var buffer = [CChar](repeating: 0, count: 256)
            let bytesRead = read(clientFD, &buffer, 255)

            if bytesRead > 0 {
                let command = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
                let response = handleCommand(command)
                let responseData = response.data(using: .utf8) ?? Data()
                _ = write(clientFD, (responseData as NSData).bytes, responseData.count)
            }

            close(clientFD)
        }

        close(fd)
    }

    private func handleCommand(_ command: String) -> String {
        guard let appDelegate = NSApp.delegate as? AppDelegate,
              let timer = appDelegate.timerManager else {
            return "{\"ok\":false,\"error\":\"no app delegate or timer\"}"
        }

        let parts = command.split(separator: " ", maxSplits: 1).map(String.init)
        let cmd = parts[0]
        let args = parts.count > 1 ? parts[1].split(separator: " ").map(String.init) : []

        switch cmd {
        case "status":
            return jsonify([
                "ok": true,
                "state": timer.state.displayText,
                "text": timer.statusBarText,
                "remaining": timer.remainingSeconds
            ])

        case "start":
            timer.start()
            return jsonify(["ok": true])

        case "pause":
            timer.pause()
            return jsonify(["ok": true])

        case "resume":
            timer.resume()
            return jsonify(["ok": true])

        case "reset":
            timer.reset()
            return jsonify(["ok": true])

        case "rest-now":
            timer.restNow()
            return jsonify(["ok": true])

        case "skip":
            timer.skipRest()
            return jsonify(["ok": true])

        case "toggle":
            if case .paused = timer.state {
                timer.resume()
            } else {
                timer.pause()
            }
            return jsonify(["ok": true])

        case "stats":
            return jsonify([
                "ok": true,
                "rounds": StatsManager.shared.roundsCompletedToday,
                "restMinutes": StatsManager.shared.totalRestMinutesToday
            ])

        case "settings":
            let s = Settings.shared
            return jsonify([
                "ok": true,
                "workDuration": s.workDuration,
                "restDuration": s.restDuration,
                "enforceRest": s.enforceRest,
                "pauseOnLock": s.pauseOnLock,
                "notifyOnWorkEnd": s.notifyOnWorkEnd,
                "notifyOnRestEnd": s.notifyOnRestEnd,
                "soundEnabled": s.soundEnabled,
                "launchAtLogin": LoginItemManager.shared.isEnabled,
                "statusBarStyle": s.statusBarStyle.rawValue
            ])

        case "set-style":
            guard args.count >= 1 else {
                return "{\"ok\":false,\"error\":\"usage: set-style <name>\"}"
            }
            let styleName = args[0]
            guard let style = Settings.StatusBarStyle(rawValue: styleName) else {
                let valid = Settings.StatusBarStyle.allCases.map { $0.rawValue }.joined(separator: ", ")
                return "{\"ok\":false,\"error\":\"unknown style: \(styleName). valid: \(valid)\"}"
            }
            Settings.shared.statusBarStyle = style
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
            return jsonify(["ok": true, "statusBarStyle": style.rawValue])

        case "quit":
            NSApp.terminate(nil)
            return jsonify(["ok": true])

        default:
            return "{\"ok\":false,\"error\":\"unknown command: \(command)\"}"
        }
    }

    private func jsonify(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
