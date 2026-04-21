//
//  LoginPromptSheet.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

/// Half-sheet shown when a guest tries to purchase a certificate
struct LoginPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.top, 8)

            // Text
            VStack(spacing: 8) {
                Text("Требуется авторизация")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Войдите или зарегистрируйтесь,\nчтобы купить сертификат")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Buttons
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
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showLogin) {
            LoginView(authViewModel: authViewModel) {
                showLogin = false
                dismiss()
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(authViewModel: authViewModel) {
                showRegister = false
                dismiss()
            }
        }
        .onChange(of: authViewModel.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn { dismiss() }
        }
    }
}
