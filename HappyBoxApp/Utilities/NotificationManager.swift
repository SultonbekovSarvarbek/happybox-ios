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

    /// Number of pre-scheduled one-shot reminders (20 × 3 days = ~60 days ahead)
    private let reminderBatchSize = 20

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
        // Only batch ids ("happybox.gift.reminder.N") count — the legacy daily
        // notification ("happybox.gift.reminder") must be replaced, not kept
        return requests.contains { $0.identifier.hasPrefix(reminderNotificationID + ".") }
    }

    /// Schedule gift reminders at 12:00 once every 3 days.
    /// iOS has no repeating "every N days" trigger, so a batch of one-shot
    /// notifications is pre-scheduled and refilled on launch once it runs out.
    func scheduleGiftReminder() {
        cancelGiftReminder()

        let localization = LocalizationManager.shared

        let content = UNMutableNotificationContent()
        content.title = localization.localized("notification.reminder.title")
        content.body = localization.localized("notification.reminder.body")
        content.sound = .default
        content.badge = 1

        let calendar = Calendar.current
        for index in 0..<reminderBatchSize {
            guard let day = calendar.date(byAdding: .day, value: (index + 1) * 3, to: Date()) else { continue }

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: day)
            dateComponents.hour = 12
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(reminderNotificationID).\(index)",
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { _ in }
        }
    }

    /// Cancel gift reminder notifications (including the legacy daily one)
    func cancelGiftReminder() {
        var ids = (0..<reminderBatchSize).map { "\(reminderNotificationID).\($0)" }
        ids.append(reminderNotificationID)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
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
