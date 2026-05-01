import Foundation
import AppKit
import Carbon

/// 将快捷键组合格式化为用户可读字符串（用于设置界面展示）
enum HotkeyDisplayFormatter {

    /// 根据 Carbon 键码与修饰键生成展示文案，例如 `⌘⇧P`
    static func displayString(keyCode: UInt32, carbonModifiers: UInt32) -> String {
        var s = ""
        if carbonModifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        if carbonModifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if carbonModifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if carbonModifiers & UInt32(controlKey) != 0 { s += "⌃" }
        s += keyCodeLabel(keyCode)
        return s
    }

    /// 将虚拟键码转为单个键位标签（字母为大写）
    static func keyCodeLabel(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_M: return "M"
        case kVK_Return, kVK_ANSI_KeypadEnter: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_CapsLock: return "⇪"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_F13: return "F13"
        case kVK_F14: return "F14"
        case kVK_F15: return "F15"
        case kVK_F16: return "F16"
        case kVK_F17: return "F17"
        case kVK_F18: return "F18"
        case kVK_F19: return "F19"
        case kVK_F20: return "F20"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        default:
            return "#\(keyCode)"
        }
    }
}

extension NSEvent.ModifierFlags {

    /// 将 `NSEvent` 修饰键映射为 Carbon 热键注册用的位掩码
    var carbonModifierMask: UInt32 {
        var mask: UInt32 = 0
        if contains(.command) { mask |= UInt32(cmdKey) }
        if contains(.shift) { mask |= UInt32(shiftKey) }
        if contains(.option) { mask |= UInt32(optionKey) }
        if contains(.control) { mask |= UInt32(controlKey) }
        return mask
    }
}

/// 全局快捷键管理器（Carbon `RegisterEventHotKey`）
final class HotkeyManager {

    static let shared = HotkeyManager()

    private var eventHandlerRef: EventHandlerRef?
    private var toggleHotkeyRef: EventHotKeyRef?
    private var restNowHotkeyRef: EventHotKeyRef?

    private init() {
        NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard (note.object as? String) == "globalHotkeys" else { return }
            self?.reload()
        }
    }

    /// 安装键盘事件回调并按 `Settings` 注册快捷键（应用生命周期内只需调用一次）
    func register() {
        installKeyboardHandlerIfNeeded()
        registerHotkeysFromSettings()
    }

    /// 从 `Settings` 重新注册快捷键（用户修改组合后调用）
    func reload() {
        unregisterHotkeyRefsOnly()
        registerHotkeysFromSettings()
    }

    /// 注销全部热键并移除事件处理器（应用退出时调用）
    func unregister() {
        unregisterHotkeyRefsOnly()
        removeKeyboardHandler()
    }

    /// 确保 `kEventHotKeyPressed` 回调已安装到应用事件目标（幂等）
    private func installKeyboardHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        var ref: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            &eventSpec,
            nil,
            &ref
        )
        if status == noErr {
            eventHandlerRef = ref
        } else {
            print("HotkeyManager: InstallEventHandler 失败 \(status)")
        }
    }

    /// 移除已安装的 `InstallEventHandler` 回调
    private func removeKeyboardHandler() {
        guard let ref = eventHandlerRef else { return }
        RemoveEventHandler(ref)
        eventHandlerRef = nil
    }

    /// 仅注销已登记的 `EventHotKeyRef`，不影响事件处理器
    private func unregisterHotkeyRefsOnly() {
        if let ref = toggleHotkeyRef {
            UnregisterEventHotKey(ref)
            toggleHotkeyRef = nil
        }
        if let ref = restNowHotkeyRef {
            UnregisterEventHotKey(ref)
            restNowHotkeyRef = nil
        }
    }

    /// 按当前 `Settings` 注册一条或两条全局热键
    private func registerHotkeysFromSettings() {
        let settings = Settings.shared

        if settings.isGlobalHotkeyToggleEnabled {
            let id = EventHotKeyID(signature: OSType(0x4547), id: 1)
            var ref: EventHotKeyRef?
            let st = RegisterEventHotKey(
                settings.globalHotkeyToggleKeyCode,
                settings.globalHotkeyToggleCarbonModifiers,
                id,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if st == noErr {
                toggleHotkeyRef = ref
                print("HotkeyManager: 计时控制键注册成功 \(HotkeyDisplayFormatter.displayString(keyCode: settings.globalHotkeyToggleKeyCode, carbonModifiers: settings.globalHotkeyToggleCarbonModifiers))")
            } else {
                print("HotkeyManager: 计时控制键注册失败 \(st)")
            }
        }

        if settings.isGlobalHotkeyRestNowEnabled {
            let id = EventHotKeyID(signature: OSType(0x4547), id: 2)
            var ref: EventHotKeyRef?
            let st = RegisterEventHotKey(
                settings.globalHotkeyRestNowKeyCode,
                settings.globalHotkeyRestNowCarbonModifiers,
                id,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if st == noErr {
                restNowHotkeyRef = ref
                print("HotkeyManager: 立即休息键注册成功 \(HotkeyDisplayFormatter.displayString(keyCode: settings.globalHotkeyRestNowKeyCode, carbonModifiers: settings.globalHotkeyRestNowCarbonModifiers))")
            } else {
                print("HotkeyManager: 立即休息键注册失败 \(st)")
            }
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
        case 1:
            switch timer.state {
            case .idle:
                timer.start()
            case .working:
                timer.pause()
            case .paused:
                timer.resume()
            case .resting:
                break
            }
        case 2:
            timer.restNow()
        default:
            break
        }
    }

    return noErr
}
