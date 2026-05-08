//
//  MobileGiftOrderDetailView.swift
//  HappyBoxApp
//

import SwiftUI

struct MobileGiftOrderDetailView: View {
    let order: MobileGiftOrder
    let mode: Mode

    enum Mode {
        case received
        case sent
    }

    @Environment(\.openURL) private var openURL

    private var isBalance: Bool { order.isBalanceBased }
    private var redeemed: Bool { order.isRedeemed }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: mode == .sent ? "paperplane.fill" : "gift.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(spacing: 6) {
                        Text(order.partner?.name ?? "Партнёр")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        if let cert = order.certificate?.name {
                            Text(cert)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: redeemed ? "checkmark.circle.fill" : "gift.fill")
                            .font(.system(size: 13))
                        Text(redeemed
                             ? (isBalance ? "Баланс израсходован" : "Использован")
                             : (mode == .sent ? "Подарок отправлен" : "Активен"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundStyle(redeemed ? Color.secondary : Color.accentColor)
                    .background((redeemed ? Color.secondary : Color.accentColor).opacity(0.12))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.systemBackground))

                Divider()

                // Balance card (balance-based)
                if isBalance, let remaining = order.formattedRemainingAmount {
                    VStack(spacing: 8) {
                        Text(redeemed ? "Израсходован" : "Остаток на сертификате")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(remaining)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(redeemed ? Color.secondary : Color.green)
                        if let r = order.remainingAmount, r < order.totalAmount {
                            Text("из \(order.formattedTotalAmount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(redeemed ? Color(.systemGray6).opacity(0.5) : Color.green.opacity(0.06))

                    Divider()
                }

                // Code (only for received and not redeemed)
                if mode == .received && !redeemed {
                    VStack(spacing: 6) {
                        Text("Ваш код")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(order.shortCode)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        Text("Покажите код партнёру")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)

                    Divider()
                }

                // Recipient / sender info
                VStack(spacing: 0) {
                    DetailRow(
                        icon: mode == .sent ? "person.crop.circle.fill" : "person.crop.circle",
                        label: mode == .sent ? "Получатель" : "Отправитель",
                        value: mode == .sent ? order.recipientName : order.senderName
                    )
                    Divider().padding(.leading, 52)
                    DetailRow(
                        icon: "phone.fill",
                        label: "Телефон",
                        value: mode == .sent ? order.recipientPhone : order.senderPhone
                    )
                    Divider().padding(.leading, 52)
                    DetailRow(icon: "calendar", label: "Дата", value: order.formattedDate)
                    if !isBalance {
                        Divider().padding(.leading, 52)
                        DetailRow(icon: "ticket.fill", label: "Сумма", value: order.formattedTotalAmount)
                    }
                }
                .background(Color(.systemBackground))

                // Redemption history (balance-based)
                if isBalance && !order.redemptions.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 0) {
                        Text("История списаний")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        ForEach(order.redemptions) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.orange)
                                    .font(.system(size: 18))
                                    .padding(.leading, 16)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.formattedAmount)
                                        .font(.system(size: 15, weight: .semibold))
                                    if let note = item.note, !note.isEmpty {
                                        Text(note).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(item.formattedDate)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 10)
                            Divider().padding(.leading, 48)
                        }
                    }
                    .background(Color(.systemBackground))
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(mode == .sent ? "Отправленный подарок" : "Подарок")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
                .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
