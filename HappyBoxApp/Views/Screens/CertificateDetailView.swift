//
//  CertificateDetailView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 07/02/26.
//

import SwiftUI

/// Detail view for a certificate with blurred location and purchase CTA
struct CertificateDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localization
    @Environment(AuthViewModel.self) private var authViewModel
    let certificate: Certificate
    @State private var showTypeSheet = false
    @State private var isSubmittingSelf = false
    @State private var showSuccess = false
    @State private var showSelfError = false
    @State private var selfErrorMessage = ""
    @State private var showLoginPrompt = false
    @State private var currentImageIndex = 0

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header image / slider
                    ZStack(alignment: .bottom) {
                        headerImageSection

                        // Bottom gradient for badge readability
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)

                        // Badge / Rating overlay (bottom-left)
                        HStack {
                            if let badge = certificate.badge {
                                HStack(spacing: 6) {
                                    Image(systemName: badge.icon)
                                        .font(.system(size: 14))
                                    Text(localization.localized(badge.localizedKey))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundStyle(badge.color)
                                .background(Color(.systemBackground).opacity(0.92))
                                .cornerRadius(8)
                            } else if let rating = certificate.rating {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundStyle(.orange)
                                .background(Color(.systemBackground).opacity(0.92))
                                .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(12)
                    }

                    // Title and description
                    VStack(alignment: .leading, spacing: 12) {
                        Text(certificate.fullTitle)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(certificate.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Price section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("certificates.price"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(certificate.formattedPriceRange)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(certificate.category.color)
                    }
                    .padding(.horizontal)

                    // Expiration date section
                    if let expirationDate = certificate.formattedExpirationDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localization.localized("certificates.validity"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 20))
                                    .foregroundStyle(
                                        certificate.isExpired ? .red :
                                        (certificate.daysUntilExpiration ?? 999) <= 30 ? .orange :
                                        certificate.category.color
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    if certificate.isExpired {
                                        Text(localization.localized("certificates.expired"))
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.red)
                                    } else if let days = certificate.daysUntilExpiration, days <= 30 {
                                        Text("\(localization.localized("certificates.expires_in")) \(days) \(localization.localized("certificates.days"))")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.orange)
                                    }

                                    Text("\(localization.localized("certificates.valid_until")): \(expirationDate)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Location section with blur
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.localized("certificates.location"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // City and district
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(certificate.category.color)
                            Text("\(localization.localized("district.all")), \(certificate.districtName)")
                                .font(.body)
                                .fontWeight(.medium)
                        }


                    }
                    .padding(.horizontal)

                    // Instagram section
                    if let handle = certificate.instagramHandle {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instagram")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button {
                                let appURL = URL(string: "instagram://user?username=\(handle)")!
                                let webURL = URL(string: "https://instagram.com/\(handle)")!
                                if UIApplication.shared.canOpenURL(appURL) {
                                    UIApplication.shared.open(appURL)
                                } else {
                                    UIApplication.shared.open(webURL)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 0.51, green: 0.25, blue: 0.74), Color(red: 0.91, green: 0.27, blue: 0.55)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("@\(handle)")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle(localization.localized("certificates.details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("product_detail.close")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Purchase CTA
                VStack(spacing: 0) {
                    Divider()

                    if certificate.isDisabled {
                        // Disabled state - Coming Soon
                        Text(localization.localized("certificates.coming_soon_message"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        // Active state - Buy Certificate
                        Button(action: {
                            if authViewModel.isLoggedIn {
                                showTypeSheet = true
                            } else {
                                showLoginPrompt = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "gift.fill")
                                Text(localization.localized("certificates.buy_certificate"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(certificate.category.color.opacity(isSubmittingSelf ? 0.5 : 1))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSubmittingSelf)
                        .padding()
                    }
                }
                .background(Color(.systemBackground))
            }
            .sheet(isPresented: $showTypeSheet) {
                CertificatePurchaseTypeView(
                    certificate: certificate,
                    currentUser: authViewModel.currentUser
                ) { _ in
                    // Both "Для себя" and "В подарок" create a purchase request
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        Task { await submitSelfPurchase() }
                    }
                }
            }
            .sheet(isPresented: $showLoginPrompt) {
                LoginPromptSheet()
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showSuccess) {
                SuccessModalView(
                    title: localization.localized("certificates.form.success_title"),
                    message: localization.localized("certificates.form.success_message"),
                    buttonTitle: localization.localized("delivery.great")
                ) {
                    NotificationCenter.default.post(name: .navigateToPurchaseRequests, object: nil)
                    dismiss()
                }
                .presentationBackground(.clear)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPurchaseRequests)) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()
                }
            }
            .alert(localization.localized("delivery.send_error"), isPresented: $showSelfError) {
                Button(localization.localized("delivery.retry")) {
                    Task { await submitSelfPurchase() }
                }
                Button(localization.localized("delivery.cancel"), role: .cancel) {}
            } message: {
                Text(selfErrorMessage)
            }
            .overlay {
                if isSubmittingSelf {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.4)
                            Text(localization.localized("delivery.sending_order"))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - Self Purchase

    @MainActor
    private func submitSelfPurchase() async {
        isSubmittingSelf = true
        do {
            try await CertificateService.shared.submitPurchaseRequest(
                certificateId: certificate.backendId,
                token: authViewModel.token
            )
            isSubmittingSelf = false
            showSuccess = true
        } catch {
            isSubmittingSelf = false
            selfErrorMessage = error.localizedDescription
            showSelfError = true
        }
    }

    // MARK: - Header Image / Slider

    @ViewBuilder
    private var headerImageSection: some View {
        if certificate.imageURLs.count > 1 {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(certificate.imageURLs.enumerated()), id: \.offset) { index, urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                headerPlaceholder
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 220)
        } else if let imageURL = certificate.imageURL, !imageURL.isEmpty,
                  let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    headerPlaceholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()
        } else {
            headerPlaceholder
        }
    }

    // MARK: - Header Placeholder

    private var headerPlaceholder: some View {
        ZStack {
            certificate.category.color.opacity(0.15)
            VStack(spacing: 12) {
                Circle()
                    .fill(certificate.category.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: certificate.category.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(certificate.category.color)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

// MARK: - Preview

#Preview {
    CertificateDetailView(certificate: CertificateData.allCertificates[0])
}
