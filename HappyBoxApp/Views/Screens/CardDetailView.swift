//
//  CardDetailView.swift
//  HappyBoxApp
//

import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localization
    @Environment(AuthViewModel.self) private var authViewModel

    let card: MobileCard

    @State private var detail: MobileCardDetail?
    @State private var services: [PartnerServiceItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCertificate: Certificate?
    @State private var selectedTab = 0
    @State private var selectedServiceIds: Set<String> = []
    @State private var showConfirm = false

    private var totalSelectedPrice: Int {
        services
            .filter { selectedServiceIds.contains($0.id) }
            .reduce(0) { $0 + $1.priceInt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    ProgressView().scaleEffect(1.2)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text(error).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Повторить") { Task { await load() } }.buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let detail {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            partnerHeader(detail: detail)
                                .padding(.horizontal)
                                .padding(.top)

                            if let banner = NotesBanner(notes: detail.notes) {
                                banner.padding(.horizontal)
                            }

                            if !services.isEmpty {
                                Picker("", selection: $selectedTab) {
                                    Text("Сертификаты").tag(0)
                                    Text("Услуги").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                            }

                            if selectedTab == 0 {
                                certificatesContent(detail: detail)
                            } else {
                                servicesContent()
                            }
                        }
                        .padding(.bottom, selectedTab == 1 && !selectedServiceIds.isEmpty ? 100 : 20)
                    }

                    if selectedTab == 1 && !selectedServiceIds.isEmpty {
                        VStack {
                            Spacer()
                            selectionBottomPanel()
                        }
                    }
                }
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("product_detail.close")) { dismiss() }
                }
            }
            .task { await load() }
            .sheet(item: $selectedCertificate) { cert in
                CertificateDetailView(certificate: cert)
            }
            .sheet(isPresented: $showConfirm) {
                CustomCertificateConfirmView(
                    card: card,
                    selectedServices: services.filter { selectedServiceIds.contains($0.id) }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPurchaseRequests)) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Certificates Tab

    @ViewBuilder
    private func certificatesContent(detail: MobileCardDetail) -> some View {
        let allCerts = certificates(from: detail)

        if allCerts.isEmpty {
            Text("Нет активных сертификатов")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 32)
        } else {
            ForEach(allCerts) { certificate in
                CertificateCard(certificate: certificate) {
                    selectedCertificate = certificate
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Services Tab

    @ViewBuilder
    private func servicesContent() -> some View {
        if services.isEmpty {
            Text("Нет доступных услуг")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 32)
        } else {
            ForEach(services) { service in
                ServiceItemRow(
                    service: service,
                    isSelected: selectedServiceIds.contains(service.id),
                    isDisabled: selectedServiceIds.count >= 5 && !selectedServiceIds.contains(service.id)
                ) {
                    toggleService(service)
                }
                .padding(.horizontal)
            }

            if selectedServiceIds.count >= 5 {
                Text("Максимум 5 услуг")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Bottom Panel

    @ViewBuilder
    private func selectionBottomPanel() -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Выбрано: \(selectedServiceIds.count) / 5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Итого: \(totalSelectedPrice.formatted()) сум")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Button("Далее") { showConfirm = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Service Toggle

    private func toggleService(_ service: PartnerServiceItem) {
        withAnimation(.spring(response: 0.25)) {
            if selectedServiceIds.contains(service.id) {
                selectedServiceIds.remove(service.id)
            } else if selectedServiceIds.count < 5 {
                selectedServiceIds.insert(service.id)
            }
        }
    }

    // MARK: - URL helper

    private func resolveURL(_ path: String) -> URL? {
        if path.hasPrefix("http") { return URL(string: path) }
        let staticBase = Bundle.main.infoDictionary?["STATIC_BASE_URL"] as? String ?? ""
        return URL(string: staticBase + path)
    }

    // MARK: - Partner Header

    @ViewBuilder
    private func partnerHeader(detail: MobileCardDetail) -> some View {
        HStack(spacing: 16) {
            if let photo = detail.photo, let url = resolveURL(photo) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: photoPlaceholder
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                photoPlaceholder.frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(detail.name).font(.system(size: 18, weight: .bold))
                if let instagram = detail.instagram, !instagram.isEmpty {
                    let handle = instagram.replacingOccurrences(of: "@", with: "")
                    Button {
                        let appURL = URL(string: "instagram://user?username=\(handle)")!
                        let webURL = URL(string: "https://instagram.com/\(handle)")!
                        if UIApplication.shared.canOpenURL(appURL) {
                            UIApplication.shared.open(appURL)
                        } else {
                            UIApplication.shared.open(webURL)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill").font(.system(size: 12))
                            Text("@\(instagram.replacingOccurrences(of: "@", with: ""))").font(.system(size: 13))
                        }
                        .foregroundStyle(LinearGradient(
                            colors: [Color(red: 0.51, green: 0.25, blue: 0.74), Color(red: 0.91, green: 0.27, blue: 0.55)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                    }
                    .buttonStyle(.plain)
                }
                if let desc = detail.description, !desc.isEmpty {
                    Text(desc).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(2)
                }
                if let locations = card.locations, !locations.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                        Text(locations.joined(separator: " · "))
                            .font(.system(size: 12))
                            .lineLimit(2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            Image(systemName: "storefront.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentColor.opacity(0.4))
        }
    }

    // MARK: - Load

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let detailTask = CertificateService.shared.fetchCardDetail(id: card.id)
            async let servicesTask = CertificateService.shared.fetchPartnerServices(cardId: card.id)
            detail = try await detailTask
            services = (try? await servicesTask) ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Map certificates

    private func certificates(from detail: MobileCardDetail) -> [Certificate] {
        let baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? ""
        return detail.certificates
            .filter { $0.isActive }
            .map { $0.toCertificate(partnerName: detail.name, baseURL: baseURL) }
    }
}

// MARK: - ServiceItemRow

private struct ServiceItemRow: View {
    let service: PartnerServiceItem
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelected ? Color.accentColor :
                        (isDisabled ? Color(.systemGray4) : Color(.systemGray2))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(service.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isDisabled && !isSelected ? Color(.systemGray2) : Color.primary)
                    if let desc = service.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Text(service.formattedPrice)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        isSelected ? Color.accentColor :
                        (isDisabled ? Color(.systemGray3) : Color.primary)
                    )
            }
            .padding(14)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.4) : Color(.systemGray5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled && !isSelected)
    }
}
