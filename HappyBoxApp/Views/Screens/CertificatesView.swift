//
//  CertificatesView.swift
//  HappyBoxApp
//

import SwiftUI

struct CertificatesView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(DeepLinkManager.self) private var deepLinkManager
    @State private var vm = CertificatesViewModel()
    @State private var searchText = ""
    @State private var selectedCard: MobileCard?
    @State private var selectedCategory: CertificateCategory?
    @State private var locationSelection: LocationSelection?
    @State private var showLocationFilter = false
    @State private var showFAQ = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(localization.localized("certificates.title"))
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 16)

                // Category chips
                if !vm.availableCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryCircleChip(
                                title: localization.localized("products.all"),
                                icon: "square.grid.2x2.fill",
                                color: .accentColor,
                                isSelected: selectedCategory == nil
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = nil }
                            }
                            ForEach(vm.availableCategories) { category in
                                CategoryCircleChip(
                                    title: localization.localized(category.localizedKey),
                                    icon: category.icon,
                                    color: category.color,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.3)) { selectedCategory = category }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    TextField(localization.localized("certificates.search_placeholder"), text: $searchText)
                        .font(.system(size: 15))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 1))
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Location filter chip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            if locationSelection != nil {
                                locationSelection = nil
                                Task { await vm.load() }
                            } else {
                                showLocationFilter = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 13))
                                Text(locationSelection?.label ?? "Все районы")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: locationSelection != nil ? "xmark.circle.fill" : "chevron.down")
                                    .font(.system(size: locationSelection != nil ? 13 : 11))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(locationSelection != nil ? .white : Color.accentColor)
                            .background(locationSelection != nil ? Color.accentColor : Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                if vm.isLoading && vm.cards.isEmpty {
                    Spacer()
                    ProgressView().scaleEffect(1.2).frame(maxWidth: .infinity)
                    Spacer()
                } else if let error = vm.errorMessage, vm.cards.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text(error).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Повторить") { Task { await vm.load() } }.buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(displayedCards) { card in
                                MobileCardRow(card: card) {
                                    selectedCard = card
                                }
                            }
                            if displayedCards.isEmpty && !vm.isLoading {
                                ComingSoonCard().padding(.top, 24)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showFAQ = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                }
            }
        }
        .task {
            await vm.load()
            handlePendingDeepLink()
        }
        .onChange(of: deepLinkManager.pendingCardHandle) { _, _ in
            handlePendingDeepLink()
        }
        .sheet(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
        .sheet(isPresented: $showLocationFilter) {
            LocationFilterSheet(selection: $locationSelection)
        }
        .sheet(isPresented: $showFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Готово") { showSettings = false }
                        }
                    }
            }
        }
        .onChange(of: locationSelection) { _, newValue in
            Task {
                await vm.load(
                    cityId: newValue?.cityId,
                    districtId: newValue?.districtId
                )
            }
        }
    }

    private func handlePendingDeepLink() {
        guard let handle = deepLinkManager.pendingCardHandle,
              !vm.cards.isEmpty else { return }

        let match = vm.cards.first {
            let cardHandle = ($0.instagram ?? "")
                .replacingOccurrences(of: "@", with: "")
                .lowercased()
            return cardHandle == handle
        }

        if let card = match {
            selectedCard = card
            deepLinkManager.pendingCardHandle = nil
        }
    }

    private var displayedCards: [MobileCard] {
        let result = vm.filtered(by: selectedCategory)
        guard !searchText.isEmpty else { return result }
        let q = searchText.lowercased()
        return result.filter {
            $0.name.lowercased().contains(q) ||
            ($0.description?.lowercased().contains(q) ?? false) ||
            ($0.instagram?.lowercased().contains(q) ?? false)
        }
    }
}

// MARK: - Card Row

private struct MobileCardRow: View {
    let card: MobileCard
    let onTap: () -> Void

    private func resolveURL(_ path: String) -> URL? {
        if path.hasPrefix("http") { return URL(string: path) }
        let staticBase = Bundle.main.infoDictionary?["STATIC_BASE_URL"] as? String ?? ""
        return URL(string: staticBase + path)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Photo
                if let photo = card.photo, let url = resolveURL(photo) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            cardPlaceholder
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    cardPlaceholder
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let desc = card.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if let count = card.certificatesCount, count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 11))
                            Text("\(count) сертификат(ов)")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(Color.accentColor)
                    }

                    if let instagram = card.instagram, !instagram.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11))
                            Text("@\(instagram.replacingOccurrences(of: "@", with: ""))")
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

                    if let locations = card.locations, !locations.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 11))
                            Text(locations.joined(separator: " · "))
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var cardPlaceholder: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            Image(systemName: "storefront.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentColor.opacity(0.4))
        }
    }
}

// MARK: - Coming Soon Card

private struct ComingSoonCard: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.accentColor.opacity(0.15), Color.pink.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: "gift.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(LinearGradient(colors: [Color.accentColor, Color.pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            VStack(spacing: 8) {
                Text("Скоро появится").font(.system(size: 18, weight: .bold))
                Text("Мы работаем над новыми партнёрами.\nСледите за обновлениями!")
                    .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36).padding(.horizontal, 24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [Color.accentColor.opacity(0.3), Color.pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
    }
}

#Preview {
    NavigationStack { CertificatesView() }
}
