//
//  MainTabView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

struct MainTabView: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(LocalizationManager.self) private var localization
    @Environment(DeepLinkManager.self) private var deepLinkManager
    @State private var selectedTab = 0

    private var network = NetworkMonitor.shared

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
            // MARK: Certificates
            NavigationStack {
                CertificatesView()
            }
            .tabItem {
                Label(localization.localized("tab.certificates"), systemImage: "gift.fill")
            }
            .tag(0)

            // MARK: Profile
            Group {
                if authViewModel.isLoggedIn {
                    ProfileView(authViewModel: authViewModel, showDismissButton: false)
                } else {
                    AuthPromptTab()
                }
            }
            .tabItem {
                Label(localization.localized("tab.profile"), systemImage: "person.fill")
            }
            .tag(1)
        }

        // Offline banner
        if !network.isConnected {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Нет подключения к интернету")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.85))
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: network.isConnected)
            .zIndex(999)
        }
        } // ZStack
        .onChange(of: deepLinkManager.pendingCardHandle) { _, handle in
            if handle != nil {
                selectedTab = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPurchaseRequests)) { _ in
            selectedTab = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NotificationCenter.default.post(name: .openPurchaseRequestsInProfile, object: nil)
            }
        }
    }
}

// MARK: - Auth Prompt Tab

private struct AuthPromptTab: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.circle")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.accentColor.opacity(0.6))
                    }

                    VStack(spacing: 8) {
                        Text("Войдите в аккаунт")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Чтобы отслеживать заявки и\nпокупать сертификаты")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        showLogin = true
                    } label: {
                        Text("Войти")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    Button {
                        showRegister = true
                    } label: {
                        Text("Регистрация")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLogin) {
                LoginView(authViewModel: authViewModel) {
                    showLogin = false
                }
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(authViewModel: authViewModel) {
                    showRegister = false
                }
            }
        }
    }
}
