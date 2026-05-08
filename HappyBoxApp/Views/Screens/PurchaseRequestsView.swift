//
//  PurchaseRequestsView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

struct PurchaseRequestsView: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel

    @State private var requests: [PurchaseRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading && requests.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)

            } else if let error = errorMessage, requests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Повторить") {
                        Task { await load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if requests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bag")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Нет заявок")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Здесь появятся ваши заказы на сертификаты")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                VStack(spacing: 0) {
                    // Info banner
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("После обработки сертификата вы можете отправить его другому человеку.")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text("Поддержка в Telegram: @happybox_manager")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.08))

                    List(requests) { request in
                        NavigationLink {
                            PurchaseRequestDetailView(request: request)
                        } label: {
                            PurchaseRequestRow(request: request)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                    .refreshable { await load() }
                }
            }
        }
        .navigationTitle("Мои заявки")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - Methods

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            requests = try await CertificateService.shared.fetchPurchaseRequests(token: authViewModel.token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - PurchaseRequestRow

private struct PurchaseRequestRow: View {
    let request: PurchaseRequest

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(request.statusColor.opacity(0.12))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(request.statusColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(request.certificate?.name ?? "Сертификат")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if !request.formattedDate.isEmpty {
                    Text(request.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if request.isPaid, let code = request.voucherCode {
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.green)
                            Text(code)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())

                        if request.isBalanceBased,
                           let remaining = request.formattedRemainingAmount,
                           !request.isRedeemed {
                            HStack(spacing: 4) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                                Text(remaining)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Text(request.localizedStatus)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(request.statusColor)
                .background(request.statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var categoryIcon: String {
        guard let val = request.certificate?.category?.value else { return "gift.fill" }
        return CertificateCategory(rawValue: val)?.icon ?? "gift.fill"
    }
}
