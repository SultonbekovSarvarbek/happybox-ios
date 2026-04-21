//
//  SettingsView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 09/01/26.
//

import SwiftUI

/// Settings screen with language selection, support, and about options
struct SettingsView: View {
    // MARK: - Properties

    @Environment(LocalizationManager.self) private var localization
    @State private var showContactSupport = false
    @State private var showAboutUs = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    // Available languages
    private let languages = [
        Language(code: "ru", name: "Русский", flag: "🇷🇺"),
        Language(code: "uz", name: "O'zbek", flag: "🇺🇿")
    ]

    // MARK: - Body

    var body: some View {
        List {
            // Language Selection Section
            Section {
                ForEach(languages) { language in
                    Button(action: {
                        localization.currentLanguage = language.code
                    }) {
                        HStack {
                            Text(language.flag)
                                .font(.title2)

                            Text(language.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if localization.currentLanguage == language.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text(localization.localized("settings.language_header"))
            }

            // Notifications Section
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)

                        Text(localization.localized("settings.notifications"))
                    }
                }
                .onChange(of: notificationsEnabled) { _, isEnabled in
                    if isEnabled {
                        // Re-enable notifications
                        Task {
                            let granted = await NotificationManager.shared.requestAuthorization()
                            if granted {
                                NotificationManager.shared.scheduleGiftReminder()
                            }
                        }
                    } else {
                        // Disable notifications
                        NotificationManager.shared.cancelGiftReminder()
                    }
                }
            } header: {
                Text(localization.localized("settings.notifications_header"))
            } footer: {
                Text(localization.localized("settings.notifications_description"))
            }

            // Support & Info Section
            Section {
                Button(action: {
                    showContactSupport = true
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)

                        Text(localization.localized("settings.contact_support"))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(action: {
                    showAboutUs = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)

                        Text(localization.localized("settings.about_us"))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(localization.localized("settings.info_section"))
            }

        }
        .navigationTitle(localization.localized("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showContactSupport) {
            ContactSupportView()
        }
        .navigationDestination(isPresented: $showAboutUs) {
            AboutUsView()
        }
    }
}

// MARK: - Language Model

struct Language: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let flag: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
