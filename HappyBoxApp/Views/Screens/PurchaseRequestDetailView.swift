//
//  PurchaseRequestDetailView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import SwiftUI

struct PurchaseRequestDetailView: View {
    // MARK: - Properties

    let request: PurchaseRequest

    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showGiftSheet = false
    @State private var showUseSelfSheet = false
    @State private var customDetail: CustomCertificateDetail?

    private var cert: PurchaseRequest.PurchaseCertificate? { request.certificate }

    private var isCustom: Bool {
        cert?.type?.value?.uppercased() == "CUSTOM"
    }

    private var categoryColor: Color {
        if isCustom { return .accentColor }
        guard let val = cert?.category?.value else { return .accentColor }
        return CertificateCategory(rawValue: val)?.color ?? .accentColor
    }

    private var categoryIcon: String {
        if isCustom { return "list.bullet.rectangle.portrait.fill" }
        guard let val = cert?.category?.value else { return "gift.fill" }
        return CertificateCategory(rawValue: val)?.icon ?? "gift.fill"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header card
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
                    Text(request.localizedStatus)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(request.statusColor)
                        .background(request.statusColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.systemBackground))

                Divider()

                // Voucher card (PAID only)
                if request.isPaid, let code = request.voucherCode {
                    let redeemed = request.isRedeemed
                    let transferred = request.isTransferred
                    let isBalance = request.isBalanceBased
                    let cardColor: Color = redeemed || transferred ? .secondary : .green
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: redeemed ? "xmark.seal.fill" : transferred ? "gift.fill" : "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(redeemed ? Color.secondary : transferred ? Color.purple : Color.green)
                            Text(redeemed
                                 ? (isBalance ? "Баланс израсходован" : "Сертификат использован")
                                 : transferred ? "Сертификат подарен"
                                 : (isBalance ? "Сертификат с балансом" : "Сертификат подтверждён"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(redeemed ? Color.secondary : transferred ? Color.purple : Color.green)
                        }

                        // Balance card (balance-based, not transferred)
                        if isBalance && !transferred, let remaining = request.formattedRemainingAmount {
                            VStack(spacing: 6) {
                                Text("Остаток на сертификате")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(remaining)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(redeemed ? Color.secondary : Color.green)
                                if let initial = request.formattedInitialAmount,
                                   let initN = request.initialAmountNumber,
                                   let remN = request.remainingAmountNumber,
                                   initN > 0, remN < initN {
                                    Text("из \(initial)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }

                        if !transferred {
                            VStack(spacing: 6) {
                                Text("Ваш код")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(code)
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundStyle(redeemed ? Color.secondary : Color.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }

                        if !redeemed && !transferred {
                            Button {
                                showUseSelfSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill.checkmark")
                                    Text("Использовать самому")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            // Gifting a partially-used balance voucher is confusing — hide it.
                            if !isBalance {
                                Button {
                                    showGiftSheet = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "paperplane.fill")
                                        Text("Отправить другому человеку")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(redeemed || transferred ? Color(.systemGray6).opacity(0.5) : Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(cardColor.opacity(0.2), lineWidth: 1)
                    )

                    Divider()
                }

                // Redemption history (balance-based only)
                if request.isBalanceBased,
                   let history = request.voucher?.redemptions,
                   !history.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("История списаний")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        ForEach(history) { item in
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

                    Divider()
                }

                // Services section (CUSTOM certificates)
                if isCustom, let services = customDetail?.services, !services.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Состав сертификата")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        ForEach(services) { service in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                                    .font(.system(size: 18))
                                    .padding(.leading, 16)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(service.name).font(.body)
                                    if let desc = service.description, !desc.isEmpty {
                                        Text(desc).font(.caption).foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if let p = service.price {
                                    Text("\(p.formatted()) сум")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.trailing, 16)
                                }
                            }
                            .padding(.vertical, 10)
                            Divider().padding(.leading, 48)
                        }

                        if let total = customDetail?.totalPrice {
                            HStack {
                                Text("Итого")
                                    .font(.headline)
                                    .padding(.leading, 16)
                                Spacer()
                                Text("\(total.formatted()) сум")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.trailing, 16)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color(.systemBackground))

                    Divider()
                }

                // Description (top)
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

                // Details list
                VStack(spacing: 0) {
                    if !request.formattedDate.isEmpty {
                        DetailRow(icon: "calendar", label: "Дата заявки", value: request.formattedDate, color: categoryColor)
                        Divider().padding(.leading, 52)
                    }

                    if request.isBalanceBased {
                        DetailRow(icon: "infinity", label: "Срок действия", value: "Бессрочно", color: categoryColor)
                        Divider().padding(.leading, 52)
                    } else if let days = cert?.validDays, days > 0 {
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

                    if let phone = cert?.phone, !phone.isEmpty {
                        DetailRow(icon: "phone.fill", label: "Телефон", value: phone, color: categoryColor)
                    }

                }
                .background(Color(.systemBackground))

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Детали заявки")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if isCustom, let certId = cert?.id {
                customDetail = try? await CertificateService.shared.fetchCustomCertificate(
                    id: certId,
                    token: authViewModel.token
                )
            }
        }
        .sheet(isPresented: $showGiftSheet) {
            GiftVoucherSheet(voucherId: request.voucherId ?? request.id, onSent: { dismiss() })
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showUseSelfSheet) {
            if let code = request.voucherCode {
                UseSelfCodeSheet(code: code, certName: cert?.name ?? "Сертификат")
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - UseSelfCodeSheet

private struct UseSelfCodeSheet: View {
    let code: String
    let certName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("Использовать самому")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(certName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("Покажите этот код сотруднику")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            Button("Закрыть") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)

            Spacer()
        }
        .padding(.horizontal, 24)
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
