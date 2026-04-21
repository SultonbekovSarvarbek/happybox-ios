//
//  ContactSupportView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 09/01/26.
//

import SwiftUI

/// Contact support screen with various contact methods
struct ContactSupportView: View {
    // MARK: - Properties

    @Environment(LocalizationManager.self) private var localization

    // MARK: - Body

    var body: some View {
        List {
            Section {
                // Telegram
                Link(destination: URL(string: "https://t.me/happybox_manager")!) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(Color.blue)
                            .font(.title3)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(localization.localized("contact.telegram"))
                                .foregroundStyle(.primary)
                                .fontWeight(.medium)

                            Text("@happybox_manager")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Phone
                Link(destination: URL(string: "tel:+998940444581")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(Color.green)
                            .font(.title3)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(localization.localized("contact.phone"))
                                .foregroundStyle(.primary)
                                .fontWeight(.medium)

                            Text("+998 (94) 044-45-81")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(localization.localized("contact.choose_method"))
            } footer: {
                Text(localization.localized("contact.always_available"))
            }

            // Working Hours Section
            Section {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localized("contact.working_hours"))
                            .fontWeight(.medium)

                        Text(localization.localized("contact.hours_247"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(localization.localized("contact.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}
