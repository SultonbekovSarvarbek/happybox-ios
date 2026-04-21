//
//  RegisterView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct RegisterView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    var authViewModel: AuthViewModel
    var onSuccess: () -> Void

    @State private var agreedToTerms = false
    @State private var showingTerms = false
    @State private var username: String = ""
    @State private var usernameAvailable: Bool? = nil   // nil = not checked yet
    @State private var isCheckingUsername = false
    @State private var checkTask: Task<Void, Never>? = nil
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var telegramUsername: String = ""
    @State private var birthDate: Date = Calendar.current.date(
        byAdding: .year, value: -18, to: Date()
    ) ?? Date()

    @FocusState private var focusedField: Field?

    private enum Field {
        case username, firstName, lastName, phone, password, confirm, telegram
    }

    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && confirmPassword != password
    }

    // MARK: - Username validation

    private var usernameError: String? {
        guard !username.isEmpty else { return nil }
        if username.count < 5  { return "Минимум 5 символов" }
        if username.count > 15 { return "Максимум 15 символов" }
        if username.contains(where: { !$0.isLetter && !$0.isNumber && $0 != "_" }) {
            return "Только буквы, цифры и _ "
        }
        return nil
    }

    private var isUsernameValid: Bool {
        username.count >= 5 && username.count <= 15 &&
        !username.contains(where: { !$0.isLetter && !$0.isNumber && $0 != "_" })
    }

    private var isFormValid: Bool {
        isUsernameValid &&
        usernameAvailable == true &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !phone.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !passwordMismatch &&
        agreedToTerms
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Invisible tap area to dismiss keyboard
                    Color.clear
                        .frame(height: 0)
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = nil }
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.accentColor)

                        Text("Регистрация")
                            .font(.system(size: 28, weight: .bold))

                        Text("Создайте аккаунт")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            AuthTextField(label: "Имя пользователя", placeholder: "например @s_sarvar", text: $username)
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .firstName }
                                .onChange(of: username) { _, new in
                                    let filtered = String(new.filter { $0 != " " }.prefix(15))
                                    if filtered != new { username = filtered; return }
                                    // Reset and schedule debounced check
                                    usernameAvailable = nil
                                    checkTask?.cancel()
                                    guard isUsernameValid else { return }
                                    isCheckingUsername = true
                                    checkTask = Task {
                                        try? await Task.sleep(for: .milliseconds(600))
                                        guard !Task.isCancelled else { return }
                                        let available = (try? await AuthService.shared.checkUsername(filtered)) ?? false
                                        await MainActor.run {
                                            usernameAvailable = available
                                            isCheckingUsername = false
                                        }
                                    }
                                }

                            if let error = usernameError {
                                Label(error, systemImage: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            } else if isCheckingUsername {
                                HStack(spacing: 6) {
                                    ProgressView().scaleEffect(0.7)
                                    Text("Проверяем...")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            } else if isUsernameValid, let available = usernameAvailable {
                                if available {
                                    Label("Свободен", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Label("Уже занят", systemImage: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            } else if username.isEmpty {
                                Text("5–15 символов, буквы/цифры/_ без пробелов")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        AuthTextField(label: "Имя", placeholder: "", text: $firstName)
                            .focused($focusedField, equals: .firstName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .lastName }

                        AuthTextField(label: "Фамилия", placeholder: "", text: $lastName)
                            .focused($focusedField, equals: .lastName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .phone }

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
                                    .onSubmit { focusedField = .telegram }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        AuthTextField(
                            label: "Telegram (необязательно)",
                            placeholder: "@username",
                            text: $telegramUsername
                        )
                        .focused($focusedField, equals: .telegram)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                        // Birth Date Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Дата рождения")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            DatePicker(
                                "",
                                selection: $birthDate,
                                in: ...Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        AuthSecureField(label: "Пароль", placeholder: "Минимум 6 символов", text: $password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirm }

                        AuthSecureField(label: "Подтверждение пароля", placeholder: "Повторите пароль", text: $confirmPassword)
                            .focused($focusedField, equals: .confirm)
                            .submitLabel(.go)
                            .onSubmit { if isFormValid { submitRegister() } }

                        if passwordMismatch {
                            Text("Пароли не совпадают")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
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

                    // Terms checkbox
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(agreedToTerms ? Color.accentColor : .secondary)
                            .onTapGesture { agreedToTerms.toggle() }

                        (Text("Я принимаю ")
                            .foregroundColor(.primary)
                        +
                        Text("Условия использования и Публичная оферта HappyBox")
                            .foregroundColor(.accentColor)
                            .underline())
                        .font(.subheadline)
                        .onTapGesture { showingTerms = true }
                    }
                    .padding(.horizontal, 24)
                    .sheet(isPresented: $showingTerms) {
                        TermsOfUseView()
                    }

                    // Register Button
                    GiftPrimaryButton(
                        "Зарегистрироваться",
                        icon: "checkmark",
                        isDisabled: authViewModel.isLoading || !isFormValid
                    ) {
                        submitRegister()
                    }
                    .padding(.horizontal, 24)

                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    Spacer(minLength: 120)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: authViewModel.errorMessage)
            .scrollDismissesKeyboard(.interactively)
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

    private func submitRegister() {
        focusedField = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthDateString = formatter.string(from: birthDate)

        Task {
            await authViewModel.register(
                username: username,
                firstName: firstName,
                lastName: lastName,
                phone: "+998\(phone)",
                password: password,
                telegramUsername: telegramUsername.isEmpty ? nil : telegramUsername,
                birthDate: birthDateString
            )
        }
    }
}
