//
//  LoginView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Passwordless login. Step 1: enter phone → backend sends a code to the user's
/// Telegram via the bot. Step 2: enter the code → logged in. Accounts are
/// created in the Telegram bot, so new users are pointed there.
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var authViewModel: AuthViewModel
    var onSuccess: () -> Void

    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var step: Step = .phone
    @FocusState private var focused: Bool

    private enum Step { case phone, code }

    private var fullPhone: String { "+998\(phone)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    if step == .phone {
                        phoneSection
                    } else {
                        codeSection
                    }

                    errorBanner
                    primaryButton

                    if step == .code {
                        codeBotHint
                    }

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.25), value: step)
                .animation(.easeInOut(duration: 0.25), value: authViewModel.errorMessage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
        .onChange(of: authViewModel.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn { onSuccess() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text(step == .phone ? "Вход" : "Введите код")
                .font(.system(size: 28, weight: .bold))

            Text(step == .phone
                 ? "Войдите по номеру телефона"
                 : "Мы отправили код в Telegram-бот HappyBox")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
    }

    private var phoneSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Телефон")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                Text("+998")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)

                TextField("901234567", text: $phone)
                    .keyboardType(.phonePad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit { primaryAction() }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .onChange(of: phone) { _, v in
                        phone = String(v.filter { $0.isNumber }.prefix(9))
                    }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 24)
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Код из Telegram")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("123456", text: $code)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit { primaryAction() }
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: code) { _, v in
                        code = String(v.filter { $0.isNumber }.prefix(6))
                    }
            }

            HStack {
                Button("Изменить номер") {
                    step = .phone
                    code = ""
                    authViewModel.errorMessage = nil
                }
                .font(.footnote)

                Spacer()

                Button("Отправить заново") {
                    Task { _ = await authViewModel.requestOtp(phone: fullPhone) }
                }
                .font(.footnote)
                .disabled(authViewModel.isLoading)
            }
        }
        .padding(.horizontal, 24)
    }

    // Shown on the code step: if the push didn't arrive, the user can open the
    // bot and read the login code there.
    private var codeBotHint: some View {
        VStack(spacing: 10) {
            Text("Не пришло уведомление? Открой Telegram-бот — код придёт туда.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: Constants.Bot.url) { openURL(url) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Открыть Telegram-бот")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    @ViewBuilder private var errorBanner: some View {
        if let error = authViewModel.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var primaryButton: some View {
        Button(action: primaryAction) {
            HStack(spacing: 10) {
                if authViewModel.isLoading {
                    ProgressView().tint(.white)
                    Text(step == .phone ? "Отправляем..." : "Входим...")
                        .fontWeight(.semibold)
                } else {
                    Text(step == .phone ? "Получить код" : "Войти")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(primaryDisabled ? Color.accentColor.opacity(0.5) : Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(14)
        }
        .disabled(primaryDisabled)
        .padding(.horizontal, 24)
    }

    private var primaryDisabled: Bool {
        if authViewModel.isLoading { return true }
        return step == .phone ? phone.count < 9 : code.count < 6
    }

    // MARK: - Actions

    private func primaryAction() {
        focused = false
        if step == .phone {
            guard phone.count >= 9 else { return }
            Task {
                let outcome = await authViewModel.requestOtp(phone: fullPhone)
                switch outcome {
                case .sent:
                    step = .code
                case .needsBot:
                    // No profile yet → send the user to the bot to register. The bot
                    // sends a login code right after sign-up, so move straight to the
                    // code step: the field is ready when the user comes back.
                    if let url = URL(string: Constants.Bot.url) { openURL(url) }
                    step = .code
                case .failed:
                    break
                }
            }
        } else {
            guard code.count == 6 else { return }
            Task { await authViewModel.verifyOtp(phone: fullPhone, code: code) }
        }
    }
}
