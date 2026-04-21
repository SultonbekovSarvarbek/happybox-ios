//
//  CertificatePurchaseTypeView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct CertificatePurchaseTypeView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let certificate: Certificate
    let currentUser: UserProfile?
    var onSelect: (_ forSelf: Bool) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Certificate chip
            HStack(spacing: 10) {
                Circle()
                    .fill(certificate.category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: certificate.category.icon)
                            .font(.system(size: 16))
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
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Text("Кому этот сертификат?")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Option cards
            VStack(spacing: 12) {
                PurchaseTypeCard(
                    icon: "person.fill",
                    title: "Для себя",
                    subtitle: currentUser.map { "Заполним ваши данные автоматически — \($0.fullName)" }
                        ?? "Заполним ваши данные автоматически",
                    color: certificate.category.color
                ) {
                    dismiss()
                    onSelect(true)
                }

                PurchaseTypeCard(
                    icon: "gift.fill",
                    title: "В подарок кому-то",
                    subtitle: "Введите имя и контакт получателя",
                    color: .pink
                ) {
                    dismiss()
                    onSelect(false)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 32)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - PurchaseTypeCard

private struct PurchaseTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            .padding(16)
            .background(color.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
