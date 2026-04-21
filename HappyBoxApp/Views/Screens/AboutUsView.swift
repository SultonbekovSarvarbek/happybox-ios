//
//  AboutUsView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 09/01/26.
//

import SwiftUI

/// About us screen with app information and company details
struct AboutUsView: View {
    // MARK: - Properties

    @Environment(LocalizationManager.self) private var localization

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Logo
                Image(systemName: "gift.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    Text(localization.localized("app.name"))
                        .font(.system(size: 36, weight: .bold))

                    Text(localization.localized("about.version"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // About Description
                VStack(alignment: .leading, spacing: 20) {
                    Text(localization.localized("about.app_section"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(localization.localized("about.description"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .padding(.vertical, 8)

                    // Mission
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.red)
                            Text(localization.localized("about.mission"))
                                .fontWeight(.semibold)
                        }

                        Text(localization.localized("about.mission_text"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.accentColor)
                            Text(localization.localized("about.what_we_offer"))
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "gift", text: localization.localized("about.feature_selection"))
                            FeatureRow(icon: "bolt.fill", text: localization.localized("about.feature_purchase"))
                            FeatureRow(icon: "iphone", text: localization.localized("about.feature_storage"))
                            FeatureRow(icon: "envelope.fill", text: localization.localized("about.feature_greeting"))
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Social Media Links
                VStack(spacing: 16) {
                    Text(localization.localized("about.social_media"))
                        .font(.headline)

                    HStack(spacing: 24) {
                        Link(destination: URL(string: "https://instagram.com/happybox_uz")!) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .pink, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                        }

                        Link(destination: URL(string: "https://t.me/happybox_uz")!) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }

                        Link(destination: URL(string: "https://facebook.com/happybox.uz")!) {
                            Image(systemName: "f.square.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.vertical, 20)

                // Copyright
                Text(localization.localized("about.copyright"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle(localization.localized("about.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutUsView()
    }
}
