//
//  ReceivedGiftsView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

struct ReceivedGiftsView: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel

    @State private var vouchers: [ReceivedVoucher] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading && vouchers.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)

            } else if let error = errorMessage, vouchers.isEmpty {
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

            } else if vouchers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gift")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Нет подарков")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Здесь появятся сертификаты, которые вам подарили")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                List(vouchers) { voucher in
                    NavigationLink {
                        ReceivedGiftDetailView(voucher: voucher)
                    } label: {
                        ReceivedGiftRow(voucher: voucher)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
                .refreshable { await load() }
            }
        }
        .navigationTitle("Мои подарки")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - Methods

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            vouchers = try await CertificateService.shared.fetchReceivedVouchers(token: authViewModel.token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - ReceivedGiftRow

private struct ReceivedGiftRow: View {
    let voucher: ReceivedVoucher

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(.purple)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.certificate?.name ?? "Сертификат")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if let partnerName = voucher.certificate?.partner?.name {
                    Text(partnerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let owner = voucher.originalOwner?.displayName, !owner.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text("От: \(owner)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !voucher.formattedDate.isEmpty {
                    Text(voucher.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let code = voucher.code, voucher.isRedeemed != true {
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.purple)
                            Text(code)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Capsule())

                        if voucher.isBalanceBased,
                           let remaining = voucher.formattedRemainingAmount {
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
        }
        .padding(.vertical, 4)
    }

    private var categoryIcon: String {
        guard let val = voucher.certificate?.category?.value else { return "gift.fill" }
        return CertificateCategory(rawValue: val)?.icon ?? "gift.fill"
    }
}
