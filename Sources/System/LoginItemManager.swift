import Foundation
import ServiceManagement

/// 登录启动管理器（SMAppService，macOS 13+）
class LoginItemManager {

    static let shared = LoginItemManager()

    private init() {}

    /// 当前是否已注册登录项
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    /// 启用登录启动
    func enable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                print("LoginItemManager: 已注册登录项")
            } catch {
                print("LoginItemManager: 注册失败 \(error)")
            }
        }
    }

    /// 禁用登录启动
    func disable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                print("LoginItemManager: 已取消登录项")
            } catch {
                print("LoginItemManager: 取消失败 \(error)")
            }
        }
    }

    /// 切换
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
