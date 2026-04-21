//
//  HappyBoxAppApp.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI
import UIKit

@main
struct HappyBoxAppApp: App {
    /// Shared cart view model for the entire app
    @State private var cartViewModel = CartViewModel()

    /// Shared auth view model
    @State private var authViewModel = AuthViewModel()

    /// Track app lifecycle for badge clearing
    @Environment(\.scenePhase) private var scenePhase

    /// User preference for notifications
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    /// App Store update state
    @State private var updateInfo: AppUpdateInfo? = nil
    @State private var showUpdateAlert = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(cartViewModel)
                .environment(LocalizationManager.shared)
                .environment(authViewModel)
                .environment(DeepLinkManager.shared)
                .onOpenURL { url in
                    DeepLinkManager.shared.handle(url: url)
                }
                .task {
                    await ProductDataService.shared.loadProducts()
                    cartViewModel.restoreCart(from: ProductDataService.shared.allProducts)
                    await setupNotifications()
                    if let info = await AppUpdateService.shared.checkForUpdate() {
                        updateInfo = info
                        showUpdateAlert = true
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        NotificationManager.shared.clearBadge()
                    }
                }
                .alert("Доступно обновление", isPresented: $showUpdateAlert) {
                    Button("Позже", role: .cancel) { }
                    Button("Обновить") {
                        if let url = updateInfo?.storeURL {
                            UIApplication.shared.open(url)
                        }
                    }
                } message: {
                    if let version = updateInfo?.version {
                        Text("Версия \(version) уже в App Store. Обновите приложение, чтобы получить новые функции.")
                    }
                }
        }
    }

    private func setupNotifications() async {
        // Wait 2 seconds so the user sees the app before the system dialog appears
        try? await Task.sleep(for: .seconds(2))
        let notificationManager = NotificationManager.shared
        let granted = await notificationManager.requestAuthorization()
        if granted && notificationsEnabled {
            let alreadyScheduled = await notificationManager.hasScheduledReminders()
            if !alreadyScheduled {
                notificationManager.scheduleGiftReminder()
            }
        }
    }
}
