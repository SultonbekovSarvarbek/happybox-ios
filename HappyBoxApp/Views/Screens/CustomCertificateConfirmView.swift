//
//  CustomCertificateConfirmView.swift
//  HappyBoxApp
//

import SwiftUI

struct CustomCertificateConfirmView: View {
    let card: MobileCard
    let selectedServices: [PartnerServiceItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var totalPrice: Int {
        selectedServices.reduce(0) { $0 + $1.priceInt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Certificate preview card
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "list.bullet.rectangle.portrait.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Color.accentColor)
                            }

                            Text(card.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("Кастомный сертификат")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top)

                        // Services list
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Услуги")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(Array(selectedServices.enumerated()), id: \.element.id) { index, service in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                            .font(.system(size: 18))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(service.name).font(.body)
                                            if let desc = service.description, !desc.isEmpty {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Text(service.formattedPrice)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                    if index < selectedServices.count - 1 {
                                        Divider().padding(.leading, 48)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }

                        if let banner = NotesBanner(notes: card.notes) {
                            banner.padding(.horizontal)
                        }

                        // Total row
                        HStack {
                            Text("Итого")
                                .font(.headline)
                            Spacer()
                            Text("\(totalPrice.formatted()) сум")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                        // Error message
                        if let err = errorMessage {
                            Text(err)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Create button
                        Button(action: createCertificate) {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Создать сертификат")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .background(isLoading ? Color.accentColor.opacity(0.6) : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(isLoading)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Ваш сертификат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Назад") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showSuccess) {
                SuccessModalView(
                    title: "Заявка создана!",
                    message: "Ваша заявка успешно отправлена. Отслеживайте её в разделе заявок.",
                    buttonTitle: "Отлично!"
                ) {
                    NotificationCenter.default.post(name: .navigateToPurchaseRequests, object: nil)
                    dismiss()
                }
                .presentationBackground(.clear)
            }
        }
    }

    private func createCertificate() {
        guard !isLoading else { return }
        guard let token = authViewModel.token else {
            errorMessage = "Необходимо авторизоваться"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let serviceIds = selectedServices.map { $0.id }
                let cert = try await CertificateService.shared.createCustomCertificate(
                    partnerCardId: card.id,
                    serviceItemIds: serviceIds,
                    token: token
                )
                try await CertificateService.shared.submitPurchaseRequest(
                    certificateId: cert.id,
                    token: token
                )
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch let apiError as APIError {
                let userMessage: String
                switch apiError.statusCode {
                case 400: userMessage = "Одна из услуг недоступна"
                case 401: userMessage = "Необходимо авторизоваться"
                case 404: userMessage = "Партнер не найден"
                default:  userMessage = apiError.serverMessage
                }
                await MainActor.run {
                    isLoading = false
                    errorMessage = userMessage
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
