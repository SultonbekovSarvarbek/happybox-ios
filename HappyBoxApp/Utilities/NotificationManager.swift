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

    /// Days of the month the gift reminder fires on (twice a month)
    private let reminderDays = [1, 15]

    /// Hour of the day (24h) the reminder fires at
    private let reminderHour = 12

    private var reminderIDs: [String] {
        reminderDays.map { "\(reminderNotificationID).day\($0)" }
    }

    /// Identifiers from previous schedules that must be cleared on migration:
    /// the daily notification and the every-3-days batch of 20 one-shots
    private var legacyReminderIDs: [String] {
        var ids = (0..<20).map { "\(reminderNotificationID).\($0)" }
        ids.append(reminderNotificationID)
        return ids
    }

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

    /// Check if gift reminders are already scheduled.
    /// Only the current identifiers count — a user still carrying a previous
    /// schedule reports `false` so it gets replaced on next launch.
    func hasScheduledReminders() async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        let pending = Set(requests.map(\.identifier))
        return reminderIDs.allSatisfy(pending.contains)
    }

    /// Schedule gift reminders at 12:00 on the 1st and 15th of every month.
    /// A calendar trigger matching only day/hour/minute repeats monthly, so two
    /// repeating requests cover the schedule indefinitely — no refill needed.
    func scheduleGiftReminder() {
        cancelGiftReminder()

        let localization = LocalizationManager.shared

        let content = UNMutableNotificationContent()
        content.title = localization.localized("notification.reminder.title")
        content.body = localization.localized("notification.reminder.body")
        content.sound = .default
        content.badge = 1

        for day in reminderDays {
            var dateComponents = DateComponents()
            dateComponents.day = day
            dateComponents.hour = reminderHour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "\(reminderNotificationID).day\(day)",
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { _ in }
        }
    }

    /// Cancel gift reminder notifications (including any from previous schedules)
    func cancelGiftReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: reminderIDs + legacyReminderIDs
        )
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
