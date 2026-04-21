//
//  CertificatePurchaseFormView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 07/02/26.
//

import SwiftUI

/// Form for purchasing a certificate
struct CertificatePurchaseFormView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localization
    @Environment(AuthViewModel.self) private var authViewModel
    let certificate: Certificate
    var prefillName: String = ""
    var prefillPhone: String = ""

    @State private var recipientName = ""
    @State private var phoneNumber = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case name, phone, message
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("certificates.form.header"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(localization.localized("certificates.form.subheader"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Certificate info notice
                    HStack(spacing: 12) {
                        Circle()
                            .fill(certificate.category.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: certificate.category.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(certificate.category.color)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(certificate.fullTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Text(certificate.formattedPriceRange)
                                .font(.caption)
                                .foregroundStyle(certificate.category.color)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(certificate.category.color.opacity(0.08))
                    .cornerRadius(12)

                    // Form fields
                    VStack(spacing: 16) {
                        // Recipient Name (Required)
                        FormField(
                            title: localization.localized("certificates.form.recipient_name"),
                            placeholder: localization.localized("certificates.form.recipient_name_placeholder"),
                            text: $recipientName,
                            icon: "person.fill",
                            isRequired: true
                        )
                        .focused($focusedField, equals: .name)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .phone
                        }

                        // Phone Number (Required)
                        FormField(
                            title: localization.localized("certificates.form.phone"),
                            placeholder: localization.localized("certificates.form.phone_placeholder"),
                            text: $phoneNumber,
                            icon: "phone.fill",
                            isRequired: true
                        )
                        .focused($focusedField, equals: .phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .message
                        }

                        // Optional Message
                        FormField(
                            title: localization.localized("certificates.form.message"),
                            placeholder: localization.localized("certificates.form.message_placeholder"),
                            text: $message,
                            icon: "text.bubble.fill",
                            isRequired: false,
                            axis: .vertical
                        )
                        .focused($focusedField, equals: .message)
                        .submitLabel(.done)
                    }

                    // Info about address
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)

                        Text(localization.localized("certificates.form.address_info"))
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)

                    // Price summary
                    VStack(spacing: 12) {
                        Divider()

                        HStack {
                            Text(localization.localized("certificates.price"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(certificate.formattedPriceRange)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(certificate.category.color)
                        }

                        Divider()
                    }

                    // Submit button
                    Button(action: submitForm) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text(localization.localized("certificates.form.submit"))
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? certificate.category.color : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSending)

                    // Loading text
                    if isSending {
                        HStack {
                            ProgressView()
                                .tint(certificate.category.color)
                            Text(localization.localized("delivery.sending_order"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Helper text
                    if !isFormValid {
                        Text(localization.localized("delivery.fill_required"))
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .onAppear {
                if recipientName.isEmpty { recipientName = prefillName }
                if phoneNumber.isEmpty   { phoneNumber = prefillPhone }
            }
            .navigationTitle(localization.localized("certificates.form.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.localized("delivery.cancel")) {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showSuccess) {
                SuccessModalView(
                    title: localization.localized("certificates.form.success_title"),
                    message: localization.localized("certificates.form.success_message"),
                    buttonTitle: localization.localized("delivery.great")
                ) {
                    NotificationCenter.default.post(name: .navigateToPurchaseRequests, object: nil)
                    dismiss()
                }
                .presentationBackground(.clear)
            }
            .alert(localization.localized("delivery.send_error"), isPresented: $showError) {
                Button(localization.localized("delivery.retry")) {
                    submitForm()
                }
                Button(localization.localized("delivery.cancel"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var isPhoneValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 9 && digits.count <= 15
    }

    private var isFormValid: Bool {
        !recipientName.trimmingCharacters(in: .whitespaces).isEmpty && isPhoneValid
    }

    // MARK: - Methods

    private func submitForm() {
        focusedField = nil
        isSending = true

        Task {
            do {
                try await CertificateService.shared.submitPurchaseRequest(
                    certificateId: certificate.backendId,
                    token: authViewModel.token
                )
                await MainActor.run {
                    isSending = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CertificatePurchaseFormView(certificate: CertificateData.allCertificates[0])
}
