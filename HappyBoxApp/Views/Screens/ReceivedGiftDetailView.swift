//
//  ReceivedGiftDetailView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

struct ReceivedGiftDetailView: View {
    // MARK: - Properties

    let voucher: ReceivedVoucher

    @Environment(\.openURL) private var openURL
    private var cert: ReceivedVoucher.VoucherCertificate? { voucher.certificate }

    private var categoryColor: Color {
        guard let val = cert?.category?.value else { return .purple }
        return CertificateCategory(rawValue: val)?.color ?? .purple
    }

    private var categoryIcon: String {
        guard let val = cert?.category?.value else { return "gift.fill" }
        return CertificateCategory(rawValue: val)?.icon ?? "gift.fill"
    }

    private var redeemed: Bool { voucher.isRedeemed == true }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: categoryIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(categoryColor)
                    }

                    VStack(spacing: 6) {
                        Text(cert?.name ?? "Сертификат")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        if let partnerName = cert?.partner?.name {
                            Text(partnerName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Status badge
                    HStack(spacing: 6) {
                        Image(systemName: redeemed ? "checkmark.circle.fill" : "gift.fill")
                            .font(.system(size: 13))
                        Text(redeemed ? "Использован" : "Подарок")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundStyle(redeemed ? Color.secondary : Color.purple)
                    .background((redeemed ? Color.secondary : Color.purple).opacity(0.12))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.systemBackground))

                Divider()

                // Voucher code card (hidden when redeemed)
                if let code = voucher.code, !redeemed {
                    VStack(spacing: 12) {
                        // Sender info
                        if let owner = voucher.originalOwner {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Text(String((owner.firstName ?? owner.username ?? "?").prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Отправил(а)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(owner.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                Spacer()
                            }

                            Divider()
                        }

                        VStack(spacing: 6) {
                            Text("Ваш код")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(code)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.purple.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )

                    Divider()
                }

                // Description
                if let desc = cert?.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Описание")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(desc)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))

                    Divider()
                }

                // Details
                VStack(spacing: 0) {
                    if !voucher.formattedDate.isEmpty {
                        DetailRow(icon: "calendar", label: "Дата получения", value: voucher.formattedDate, color: categoryColor)
                        Divider().padding(.leading, 52)
                    }

                    if let days = cert?.validDays, days > 0 {
                        DetailRow(icon: "clock.fill", label: "Срок действия", value: "\(days) дней", color: categoryColor)
                        Divider().padding(.leading, 52)
                    }

                    if let location = cert?.locationString {
                        DetailRow(icon: "mappin.circle.fill", label: "Район", value: location, color: categoryColor)
                        Divider().padding(.leading, 52)
                    }

                    if let handle = cert?.instagram, !handle.isEmpty {
                        let clean = handle.replacingOccurrences(of: "@", with: "")
                        Button {
                            openInstagram(username: clean, openURL: openURL)
                        } label: {
                            DetailRow(icon: "camera.fill", label: "Instagram", value: "@\(clean)", color: categoryColor)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 52)
                    }

                }
                .background(Color(.systemBackground))

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Подарок")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helpers

private func openInstagram(username: String, openURL: OpenURLAction) {
    if let url = URL(string: "https://instagram.com/\(username)") {
        openURL(url)
    }
}

// MARK: - DetailRow

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
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
