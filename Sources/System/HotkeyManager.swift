import Foundation
import AppKit
import Carbon

/// 全局快捷键管理器
class HotkeyManager {

    static let shared = HotkeyManager()

    private var startHotkeyRef: EventHotKeyRef?
    private var pauseHotkeyRef: EventHotKeyRef?

    private init() {}

    func register() {
        // 安装事件处理
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            &eventSpec,
            nil,
            nil
        )

        // ⌘⇧E 启动
        let startID = EventHotKeyID(signature: OSType(0x4547), id: 1)
        var startRef: EventHotKeyRef?
        let status1 = RegisterEventHotKey(
            UInt32(kVK_ANSI_E),
            UInt32(cmdKey | shiftKey),
            startID,
            GetApplicationEventTarget(),
            0,
            &startRef
        )
        if status1 == noErr {
            startHotkeyRef = startRef
            print("HotkeyManager: ⌘⇧E 注册成功")
        } else {
            print("HotkeyManager: ⌘⇧E 注册失败 \(status1)")
        }

        // ⌘⇧P 暂停
        let pauseID = EventHotKeyID(signature: OSType(0x4547), id: 2)
        var pauseRef: EventHotKeyRef?
        let status2 = RegisterEventHotKey(
            UInt32(kVK_ANSI_P),
            UInt32(cmdKey | shiftKey),
            pauseID,
            GetApplicationEventTarget(),
            0,
            &pauseRef
        )
        if status2 == noErr {
            pauseHotkeyRef = pauseRef
            print("HotkeyManager: ⌘⇧P 注册成功")
        } else {
            print("HotkeyManager: ⌘⇧P 注册失败 \(status2)")
        }
    }

    func unregister() {
        if let ref = startHotkeyRef {
            UnregisterEventHotKey(ref)
            startHotkeyRef = nil
        }
        if let ref = pauseHotkeyRef {
            UnregisterEventHotKey(ref)
            pauseHotkeyRef = nil
        }
    }
}

// MARK: - Carbon 事件回调

private let hotkeyCallback: EventHandlerUPP = { _, event, _ in
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotkeyID = EventHotKeyID()
    let result = GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    guard result == noErr else { return OSStatus(eventNotHandledErr) }

    DispatchQueue.main.async {
        guard let appDelegate = NSApp.delegate as? AppDelegate,
              let timer = appDelegate.timerManager else { return }

        switch hotkeyID.id {
        case 1: // ⌘⇧E 启动/继续
            switch timer.state {
            case .idle:
                timer.start()
            case .paused:
                timer.resume()
            default:
                break
            }
        case 2: // ⌘⇧P 暂停
            if case .working = timer.state {
                timer.pause()
            }
        default:
            break
        }
    }

    return noErr
}
