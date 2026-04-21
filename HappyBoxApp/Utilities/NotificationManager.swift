//
//  NotificationManager.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 02/02/26.
//

import Foundation
import UserNotifications

/// Manages local notifications for the app
@Observable
final class NotificationManager {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    private(set) var isAuthorized = false
    private let notificationCenter = UNUserNotificationCenter.current()

    private let reminderNotificationID = "happybox.gift.reminder"

    // MARK: - Init

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Check current authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Request notification permissions from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule Notifications

    /// Check if gift reminders are already scheduled
    func hasScheduledReminders() async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.contains { $0.identifier == reminderNotificationID }
    }

    /// Schedule a daily repeating notification to remind about gifts
    func scheduleGiftReminder() {
        cancelGiftReminder()

        let localization = LocalizationManager.shared

        let content = UNMutableNotificationContent()
        content.title = localization.localized("notification.reminder.title")
        content.body = localization.localized("notification.reminder.body")
        content.sound = .default
        content.badge = 1

        // Every day at 12:00
        var dateComponents = DateComponents()
        dateComponents.hour = 12
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: reminderNotificationID,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { _ in }
    }

    /// Cancel gift reminder notification
    func cancelGiftReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderNotificationID])
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Clear badge count
    func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
}
