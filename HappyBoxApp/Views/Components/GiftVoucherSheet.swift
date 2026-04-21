//
//  GiftVoucherSheet.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

struct GiftVoucherSheet: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let voucherId: String
    var onSent: (() -> Void)? = nil

    enum SearchMode: String, CaseIterable {
        case username = "Username"
        case phone    = "Телефон"
    }

    @State private var searchMode: SearchMode = .username
    @State private var username: String = ""
    @State private var foundUser: UserSearchResult? = nil
    @State private var isSearching = false
    @State private var isSending = false
    @State private var searchError: String? = nil
    @State private var sendError: String? = nil
    @State private var didSend = false

    private var invitationText: String {
        "Я отправил(а) тебе подарок в HappyBox.\nСкачай приложение и зарегистрируйся, чтобы получить сертификат:\nhttps://apps.apple.com/uz/app/id6758584836"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if didSend {
                    successView
                } else {
                    searchView
                }
            }
            .navigationTitle("Отправить сертификат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .disabled(isSending)
                }
            }
        }
    }

    // MARK: - Search view

    private var searchView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 24)

                Text("Найти получателя")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                // Mode picker
                Picker("Поиск по", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .onChange(of: searchMode) { _, _ in
                    username = ""
                    foundUser = nil
                    searchError = nil
                }

                // Search field
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        Text(searchMode == .username ? "@" : "+998")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 14)

                        TextField(searchMode == .username ? "username" : "901234567", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(searchMode == .phone ? .phonePad : .default)
                            .submitLabel(.search)
                            .onSubmit { searchUser() }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 8)
                            .onChange(of: username) { _, _ in
                                foundUser = nil
                                searchError = nil
                            }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let error = searchError {
                        if error == "not_found" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Пользователь не найден.")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Text("Мы отправим приглашение в HappyBox.\nПосле регистрации он сможет получить ваш сертификат.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Button(action: openMessages) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 13))
                                        Text("Отправить сообщение")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.green.opacity(0.12))
                                    .foregroundStyle(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal, 4)
                        } else {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Search button
                Button(action: searchUser) {
                    HStack(spacing: 8) {
                        if isSearching {
                            ProgressView().tint(.white)
                            Text("Поиск...")
                                .fontWeight(.semibold)
                        } else {
                            Text("Найти")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(username.trimmingCharacters(in: .whitespaces).isEmpty || isSearching
                                ? Color.accentColor.opacity(0.5)
                                : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                .padding(.horizontal, 24)

                // Found user card
                if let user = foundUser {
                    VStack(spacing: 16) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Text(String((user.firstName ?? user.username).prefix(1)).uppercased())
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                if let firstName = user.firstName, !firstName.isEmpty {
                                    Text(firstName)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text("@\(user.username.replacingOccurrences(of: "@", with: ""))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.green)
                        }

                        if let error = sendError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: sendGift) {
                            HStack(spacing: 8) {
                                if isSending {
                                    ProgressView().tint(.white)
                                    Text("Отправляем...")
                                        .fontWeight(.semibold)
                                } else {
                                    Image(systemName: "gift.fill")
                                    Text("Отправить")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isSending ? Color.green.opacity(0.5) : Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSending)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Success view

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text("Сертификат отправлен!")
                    .font(.title2)
                    .fontWeight(.bold)

                if let user = foundUser {
                    Text("Получатель: @\(user.username.replacingOccurrences(of: "@", with: ""))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Готово") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func searchUser() {
        let raw = username.trimmingCharacters(in: .whitespaces)
        let query: String
        if searchMode == .phone {
            let digits = raw.filter(\.isNumber)
            guard !digits.isEmpty else { return }
            query = "+998\(digits)"
        } else {
            query = raw.replacingOccurrences(of: "@", with: "")
            guard !query.isEmpty else { return }
        }

        isSearching = true
        searchError = nil
        foundUser = nil

        Task {
            do {
                let result = try await CertificateService.shared.searchUser(
                    username: searchMode == .phone ? nil : query,
                    phone: searchMode == .phone ? query : nil,
                    token: authViewModel.token
                )
                await MainActor.run {
                    foundUser = result
                    isSearching = false
                }
            } catch let error as APIError where error.statusCode == 404 {
                await MainActor.run {
                    searchError = "not_found"
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchError = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }

    private func openMessages() {
        let body = invitationText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:&body=\(body)") {
            openURL(url)
        }
    }

    private func sendGift() {
        guard let user = foundUser else { return }
        let toUsername = user.username.replacingOccurrences(of: "@", with: "")

        isSending = true
        sendError = nil

        Task {
            do {
                try await CertificateService.shared.giftVoucher(
                    voucherId: voucherId,
                    toUsername: toUsername,
                    token: authViewModel.token
                )
                await MainActor.run {
                    isSending = false
                    didSend = true
                    dismiss()
                    onSent?()
                }
            } catch {
                await MainActor.run {
                    sendError = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}
