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
                // Image header or fallback
                ZStack(alignment: .topLeading) {
                    if let imageURL = certificate.imageURL, !imageURL.isEmpty,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                imagePlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140)
                                    .clipped()
                            case .failure:
                                imagePlaceholder
                            @unknown default:
                                imagePlaceholder
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipped()
                    } else {
                        imagePlaceholder
                    }

                }
                .overlay(alignment: .topTrailing) {
                    // Badge overlay (top-right)
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
                        .background(Color(.systemBackground).opacity(0.92))
                        .cornerRadius(8)
                        .padding(8)
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
                        .background(Color(.systemBackground).opacity(0.92))
                        .cornerRadius(8)
                        .padding(8)
                    }
                }
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(certificate.fullTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(certificate.isDisabled ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

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

    // MARK: - Image Placeholder

    private var imagePlaceholder: some View {
        ZStack {
            Color(.systemGray6)
            Image(systemName: "photo")
                .font(.system(size: 36))
                .foregroundStyle(Color(.systemGray3))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
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
