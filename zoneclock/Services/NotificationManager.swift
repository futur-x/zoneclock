//
//  NotificationManager.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#endif

/// 通知管理器 - 处理应用通知
class NotificationManager: NSObject, NotificationService {
    // MARK: - Singleton
    static let shared = NotificationManager()

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isDNDEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "dndEnabled")
    }

    // MARK: - Initialization
    override private init() {
        super.init()
        notificationCenter.delegate = self
    }

    // MARK: - Permission Methods

    /// 请求通知权限
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        notificationCenter.requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notificationEnabled")
                completion(granted)
            }

            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// 检查通知权限状态
    func checkNotificationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - NotificationService Protocol

    /// 发送微休息通知
    func sendMicroBreakNotification() {
        guard !isDNDEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "微休息时间"
        content.body = "放松10秒，保持专注力"
        content.sound = .default
        content.categoryIdentifier = "microBreakNotification"

        // 添加振动（iOS）
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        sendNotification(content: content, identifier: "microBreak")
    }

    /// 发送周期完成通知
    func sendCycleCompleteNotification() {
        guard !isDNDEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "专注周期完成"
        content.body = "太棒了！您完成了90分钟的专注"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.mp3"))
        content.categoryIdentifier = "cycleCompleteNotification"

        // 添加振动（iOS）
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        sendNotification(content: content, identifier: "cycleComplete")
    }

    /// 发送休息完成通知
    func sendBreakCompleteNotification() {
        guard !isDNDEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "休息结束"
        content.body = "准备好开始新的专注周期了吗？"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle.mp3"))
        content.categoryIdentifier = "breakCompleteNotification"

        sendNotification(content: content, identifier: "breakComplete")
    }

    /// 发送提醒通知
    func sendReminderNotification(title: String, body: String) {
        guard !isDNDEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "reminderNotification"

        sendNotification(content: content, identifier: "reminder_\(Date().timeIntervalSince1970)")
    }

    // MARK: - Private Methods

    /// 发送通知
    private func sendNotification(content: UNMutableNotificationContent, identifier: String) {
        // 立即触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// 取消所有待处理的通知
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// 清除所有已发送的通知
    func clearAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Notification Actions

    /// 设置通知操作
    func setupNotificationActions() {
        // 微休息操作
        let skipAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "跳过",
            options: []
        )

        let microBreakCategory = UNNotificationCategory(
            identifier: "microBreakNotification",
            actions: [skipAction],
            intentIdentifiers: [],
            options: []
        )

        // 周期完成操作
        let startBreakAction = UNNotificationAction(
            identifier: "START_BREAK_ACTION",
            title: "开始休息",
            options: [.foreground]
        )

        let skipBreakAction = UNNotificationAction(
            identifier: "SKIP_BREAK_ACTION",
            title: "跳过休息",
            options: []
        )

        let cycleCompleteCategory = UNNotificationCategory(
            identifier: "cycleCompleteNotification",
            actions: [startBreakAction, skipBreakAction],
            intentIdentifiers: [],
            options: []
        )

        // 休息完成操作
        let startNewCycleAction = UNNotificationAction(
            identifier: "START_NEW_CYCLE_ACTION",
            title: "开始新周期",
            options: [.foreground]
        )

        let laterAction = UNNotificationAction(
            identifier: "LATER_ACTION",
            title: "稍后",
            options: []
        )

        let breakCompleteCategory = UNNotificationCategory(
            identifier: "breakCompleteNotification",
            actions: [startNewCycleAction, laterAction],
            intentIdentifiers: [],
            options: []
        )

        // 注册通知分类
        notificationCenter.setNotificationCategories([
            microBreakCategory,
            cycleCompleteCategory,
            breakCompleteCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    /// 当应用在前台时接收通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }

    /// 用户点击通知时的处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case "START_BREAK_ACTION":
            // 开始休息
            NotificationCenter.default.post(name: .startBreak, object: nil)

        case "SKIP_BREAK_ACTION":
            // 跳过休息
            NotificationCenter.default.post(name: .skipBreak, object: nil)

        case "START_NEW_CYCLE_ACTION":
            // 开始新周期
            NotificationCenter.default.post(name: .startNewCycle, object: nil)

        case "SKIP_ACTION", "LATER_ACTION":
            // 跳过或稍后
            break

        default:
            // 默认点击
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startBreak = Notification.Name("startBreak")
    static let skipBreak = Notification.Name("skipBreak")
    static let startNewCycle = Notification.Name("startNewCycle")
}