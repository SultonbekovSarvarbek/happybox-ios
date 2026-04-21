//
//  AuthViewModel.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation
import Observation

@Observable
class AuthViewModel {
    // MARK: - Auth State

    var isLoggedIn: Bool = false
    var token: String? = nil
    var currentUser: UserProfile? = nil

    // MARK: - Loading / Error

    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Keys

    private static let tokenKey = "happybox.auth.token"
    private static let profileKey = "happybox.auth.profile"

    // MARK: - Init

    init() {
        restoreSession()
        NotificationCenter.default.addObserver(
            forName: .authTokenExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.logout()
            }
        }
    }

    // MARK: - Login

    @MainActor
    func login(phone: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AuthService.shared.login(phone: phone, password: password)
            guard let t = response.resolvedToken else {
                errorMessage = "Не удалось получить токен авторизации."
                isLoading = false
                return
            }
            saveToken(t)
            // Fetch real profile from server
            let profile = try await AuthService.shared.fetchProfile(token: t)
            saveProfile(profile)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Register

    @MainActor
    func register(
        username: String,
        firstName: String,
        lastName: String,
        phone: String,
        password: String,
        telegramUsername: String?,
        birthDate: String
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AuthService.shared.register(
                username: username,
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                password: password,
                telegramUsername: telegramUsername,
                birthDate: birthDate
            )
            guard let t = response.resolvedToken else {
                errorMessage = "Не удалось получить токен авторизации."
                isLoading = false
                return
            }
            saveToken(t)
            // Fetch real profile from server (gets id and all server-side fields)
            let profile = try await AuthService.shared.fetchProfile(token: t)
            saveProfile(profile)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Refresh Profile

    @MainActor
    func refreshProfile() async {
        guard let t = token else { return }
        do {
            let profile = try await AuthService.shared.fetchProfile(token: t)
            saveProfile(profile)
        } catch {
        }
    }

    // MARK: - Logout

    @MainActor
    func logout() {
        let savedToken = token
        // Clear local state immediately so UI updates right away
        token = nil
        currentUser = nil
        isLoggedIn = false
        KeychainHelper.shared.delete(key: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: Self.profileKey)
        // Notify server in background (fire-and-forget)
        if let t = savedToken {
            Task {
                try? await AuthService.shared.logout(token: t)
            }
        }
    }

    // MARK: - Private

    private func saveToken(_ t: String) {
        token = t
        KeychainHelper.shared.save(t, key: Self.tokenKey)
    }

    private func saveProfile(_ profile: UserProfile) {
        currentUser = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.profileKey)
        }
    }

    private func restoreSession() {
        guard let saved = KeychainHelper.shared.read(key: Self.tokenKey), !saved.isEmpty else {
            return
        }
        token = saved
        // Load cached profile immediately so UI is populated while refresh happens
        if let data = UserDefaults.standard.data(forKey: Self.profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
        }
        isLoggedIn = true
        // Silently refresh profile in background
        Task { await refreshProfile() }
    }
}
