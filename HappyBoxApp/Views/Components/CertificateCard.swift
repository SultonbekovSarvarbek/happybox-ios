//
//  CertificateCard.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 07/02/26.
//

import SwiftUI

/// Card component for displaying a certificate/coupon
struct CertificateCard: View {
    // MARK: - Properties

    @Environment(LocalizationManager.self) private var localization
    let certificate: Certificate
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                // Title with badge/rating
                HStack(alignment: .top, spacing: 8) {
                    Text(certificate.fullTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(certificate.isDisabled ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    if let badge = certificate.badge {
                        HStack(spacing: 4) {
                            Image(systemName: badge.icon)
                                .font(.system(size: 10))
                            Text(localization.localized(badge.localizedKey))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(badge.color)
                        .background(badge.color.opacity(0.1))
                        .cornerRadius(8)
                    } else if let rating = certificate.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(Color(red: 0.9, green: 0.65, blue: 0.1))
                        .background(Color(red: 0.9, green: 0.65, blue: 0.1).opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // Description
                Text(certificate.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                    Text("\(localization.localized("district.all")), \(certificate.districtName)")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)

                // Price
                Text(certificate.formattedPriceRange)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(certificate.isDisabled ? .secondary : certificate.category.color)

                // Expiration date
                if let expirationDate = certificate.formattedExpirationDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12))
                        if let days = certificate.daysUntilExpiration, days <= 30 {
                            Text("\(localization.localized("certificates.expires")): \(expirationDate)")
                                .font(.system(size: 12, weight: .medium))
                        } else {
                            Text("\(localization.localized("certificates.valid_until")): \(expirationDate)")
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundStyle(
                        certificate.isExpired ? .red :
                        (certificate.daysUntilExpiration ?? 999) <= 30 ? .orange : .secondary
                    )
                }

                // Instagram handle
                if let handle = certificate.instagramHandle {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                        Text("@\(handle)")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.51, green: 0.25, blue: 0.74), Color(red: 0.91, green: 0.27, blue: 0.55)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }

                // Action button
                HStack {
                    Spacer()
                    Text(certificate.isDisabled
                         ? localization.localized("certificates.learn_more")
                         : localization.localized("certificates.learn_more"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(certificate.isDisabled ? .secondary : certificate.category.color)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(certificate.isDisabled ? .secondary : certificate.category.color)
                }
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: certificate.category.color.opacity(0.08), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(certificate.category.color.opacity(0.1), lineWidth: 1)
            )
            .opacity(certificate.isDisabled ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(false) // Always allow tap to see details
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CertificateCard(
                certificate: CertificateData.allCertificates[0],
                onTap: {}
            )
            CertificateCard(
                certificate: CertificateData.allCertificates[4],
                onTap: {}
            )
        }
        .padding()
    }
}
