//
//  HomeView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Landing screen for the HappyBox app
struct HomeView: View {
    // MARK: - Properties

    @Environment(LocalizationManager.self) private var localization
    @Binding var selectedTab: Int
    @State private var showFAQ = false
    @State private var showSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color.accentColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // App Icon/Logo
                    Image(systemName: "gift.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 20)

                    // App Title & Subtitle
                    VStack(spacing: 12) {
                        Text(localization.localized("app.name"))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(localization.localized("home.subtitle"))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    // CTA Buttons
                    VStack(spacing: 16) {
                        GiftPrimaryButton(
                            localization.localized("home.choose_ready"),
                            icon: "sparkles"
                        ) {
                            selectedTab = 1
                        }
                        .padding(.horizontal, 32)

                        Text(localization.localized("home.occasions"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 50)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFAQ = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Готово") { showSettings = false }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(selectedTab: .constant(0))
}
