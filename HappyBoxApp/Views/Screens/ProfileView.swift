//
//  ProfileView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct ProfileView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    var authViewModel: AuthViewModel
    var showDismissButton: Bool = true

    @State private var navigationPath = NavigationPath()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // Avatar + Name header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 64, height: 64)

                            Text(initials)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fullName)
                                .font(.system(size: 18, weight: .semibold))

                            if let username = authViewModel.currentUser?.username, !username.isEmpty {
                                (Text("Ваш username: ")
                                    .foregroundColor(.secondary)
                                + Text("@\(username.replacingOccurrences(of: "@", with: ""))")
                                    .foregroundColor(.accentColor))
                                .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Contact info
                if let user = authViewModel.currentUser {
                    Section("Контакты") {
                        if !user.phone.isEmpty {
                            ProfileRow(icon: "phone.fill", label: "Телефон", value: user.phone)
                        }
                        if let tg = user.telegramUsername, !tg.isEmpty {
                            ProfileRow(
                                icon: "paperplane.fill",
                                label: "Telegram",
                                value: tg.hasPrefix("@") ? tg : "@\(tg)"
                            )
                        }
                    }

                    if !user.birthDate.isEmpty {
                        Section("Личные данные") {
                            ProfileRow(
                                icon: "calendar",
                                label: "Дата рождения",
                                value: formattedDate(user.birthDate)
                            )
                        }
                    }
                }

                // My orders & gifts
                Section {
                    NavigationLink {
                        PurchaseRequestsView()
                    } label: {
                        HStack {
                            Image(systemName: "bag.fill")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)
                            Text("Мои заявки")
                        }
                    }

                    NavigationLink {
                        ReceivedGiftsView()
                    } label: {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)
                            Text("Мои подарки")
                        }
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Выйти из аккаунта")
                        }
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showDismissButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Готово") { dismiss() }
                    }
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "purchaseRequests" {
                    PurchaseRequestsView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openPurchaseRequestsInProfile)) { _ in
                navigationPath.append("purchaseRequests")
            }
        }
    }

    // MARK: - Helpers

    private var fullName: String {
        authViewModel.currentUser?.fullName ?? "Пользователь"
    }

    private var initials: String {
        guard let user = authViewModel.currentUser else { return "?" }
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        let combined = (first + last).uppercased()
        return combined.isEmpty ? (user.username.prefix(1).uppercased()) : combined
    }

    private func formattedDate(_ raw: String) -> String {
        let output = DateFormatter()
        output.dateStyle = .long
        output.timeStyle = .none
        output.locale = Locale(identifier: "ru_RU")

        // Try full ISO 8601 with time (e.g. 2008-02-27T00:00:00.000Z)
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFull.date(from: raw) {
            return output.string(from: date)
        }

        // Try date-only (e.g. 2008-02-27)
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        if let date = dateOnly.date(from: raw) {
            return output.string(from: date)
        }

        return raw
    }
}

// MARK: - ProfileRow

private struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 2)
    }
}
