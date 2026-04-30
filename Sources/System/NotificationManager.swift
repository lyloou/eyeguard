import Foundation
import AppKit
import UserNotifications

/// 通知管理器（UNUserNotificationCenter）
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    /// 通知类别标识
    private enum Category {
        static let restStart = "REST_START"
        static let restEnd = "REST_END"
    }

    /// 点击通知的 action 标识
    private enum Action {
        static let focus = "FOCUS_APP"
    }

    // MARK: - Setup

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("NotificationManager: 授权失败 \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }

        // 注册通知类别（点击行为）
        registerCategories()
    }

    private func registerCategories() {
        let center = UNUserNotificationCenter.current()

        // 点击"查看"→聚焦 App
        let focusAction = UNNotificationAction(
            identifier: Action.focus,
            title: "查看",
            options: [.foreground]
        )

        let restStartCategory = UNNotificationCategory(
            identifier: Category.restStart,
            actions: [focusAction],
            intentIdentifiers: [],
            options: []
        )

        let restEndCategory = UNNotificationCategory(
            identifier: Category.restEnd,
            actions: [focusAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([restStartCategory, restEndCategory])
    }

    // MARK: - Send

    /// 工作结束 → 提醒休息
    func notifyRestStart(workMinutes: Int, restMinutes: Int) {
        guard Settings.shared.notifyOnWorkEnd else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.notifyRestStartTitle
        content.body = L10n.notifyRestStartBody(work: workMinutes, rest: restMinutes)
        content.sound = .default
        content.categoryIdentifier = Category.restStart

        // 立即发送
        sendNotification(content: content, identifier: "rest-start-\(Date().timeIntervalSince1970)")
    }

    /// 休息结束 → 提醒继续工作
    func notifyRestEnd() {
        guard Settings.shared.notifyOnRestEnd else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.notifyRestEndTitle
        content.body = L10n.notifyRestEndBody
        content.sound = .default
        content.categoryIdentifier = Category.restEnd

        sendNotification(content: content, identifier: "rest-end-\(Date().timeIntervalSince1970)")
    }

    private func sendNotification(content: UNNotificationContent, identifier: String) {
        let trigger: UNNotificationTrigger? = nil // 立即发送
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationManager: 发送失败 \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 点击通知 → 聚焦 App
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NSApp.activate(ignoringOtherApps: true)
        completionHandler()
    }

    /// 通知展示时（前台也展示）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
