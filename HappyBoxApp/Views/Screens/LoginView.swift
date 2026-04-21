//
//  LoginView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct LoginView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    var authViewModel: AuthViewModel
    var onSuccess: () -> Void

    @State private var phone: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case phone, password }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.accentColor)

                        Text("Вход")
                            .font(.system(size: 28, weight: .bold))

                        Text("Войдите в свой аккаунт")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Fields
                    VStack(spacing: 16) {
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
                                    .focused($focusedField, equals: .phone)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .password }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        AuthSecureField(
                            label: "Пароль",
                            placeholder: "Введите пароль",
                            text: $password
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submitLogin() }
                    }
                    .padding(.horizontal, 24)

                    // Error
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

                    // Login Button
                    Button(action: submitLogin) {
                        HStack(spacing: 10) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                Text("Входим...")
                                    .fontWeight(.semibold)
                            } else {
                                Text("Войти")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (authViewModel.isLoading || phone.isEmpty || password.isEmpty)
                                ? Color.accentColor.opacity(0.5)
                                : Color.accentColor
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(authViewModel.isLoading || phone.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)

                    Spacer()
                }
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

    // MARK: - Private

    private func submitLogin() {
        focusedField = nil
        Task { await authViewModel.login(phone: "+998\(phone)", password: password) }
    }
}
