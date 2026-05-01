import AppKit

/// 通用浮窗基类 — 保证点击时始终重新激活 EyeGuard 并成为 key window
class AppPanel: NSPanel {

    override var canBecomeKey: Bool { true }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
            makeKeyAndOrderFront(nil)
        }
    }
}
