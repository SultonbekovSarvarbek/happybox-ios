//
//  SentGiftsView.swift
//  HappyBoxApp
//

import SwiftUI

struct SentGiftsView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var orders: [MobileGiftOrder] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && orders.isEmpty {
                VStack { Spacer(); ProgressView(); Spacer() }
                    .frame(maxWidth: .infinity)
            } else if let error = errorMessage, orders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Повторить") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if orders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Нет отправленных подарков")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Здесь появятся подарки, которые вы отправили через gift.happybox.uz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(orders) { order in
                    NavigationLink {
                        MobileGiftOrderDetailView(order: order, mode: .sent)
                    } label: {
                        SentGiftRow(order: order)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
                .refreshable { await load() }
            }
        }
        .navigationTitle("Я подарил")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            orders = try await CertificateService.shared.fetchSentGiftOrders(token: authViewModel.token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct SentGiftRow: View {
    let order: MobileGiftOrder

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(order.partner?.name ?? "Партнёр")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text("Для: \(order.recipientName) (\(order.recipientPhone))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !order.formattedDate.isEmpty {
                    Text(order.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text(order.formattedTotalAmount)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())

                    if order.isBalanceBased,
                       !order.isRedeemed,
                       let r = order.formattedRemainingAmount {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                            Text(r)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
