//
//  ProductSelectionView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Product browsing and selection screen
struct ProductSelectionView: View {
    // MARK: - Properties

    @Environment(CartViewModel.self) private var cart
    @Environment(LocalizationManager.self) private var localization
    @State private var navigateToSummary = false
    @State private var selectedSubcategory: GiftSubcategory?
    @State private var selectedProductForDetail: GiftProduct?
    @State private var searchText = ""

    // Grid layout columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Colors for category circles
    private static let categoryColors: [Color] = [
        .purple, .pink, .orange, .blue, .green, .brown, .red, .cyan, .indigo, .mint
    ]

    // Reference to product service
    private var productService = ProductDataService.shared

    // Displayed subcategories based on filter and search
    private var displayedSubcategories: [GiftSubcategory] {
        let baseSubcategories: [GiftSubcategory]
        if let selected = selectedSubcategory {
            baseSubcategories = [selected]
        } else {
            baseSubcategories = productService.categories.first?.subcategories ?? []
        }

        // If no search text, return as-is
        guard !searchText.isEmpty else {
            return baseSubcategories
        }

        // Filter products within each subcategory based on search text
        let lowercasedSearch = searchText.lowercased()
        return baseSubcategories.compactMap { subcategory in
            let filteredProducts = subcategory.products.filter { product in
                product.name.lowercased().contains(lowercasedSearch) ||
                product.description.lowercased().contains(lowercasedSearch)
            }

            // Only include subcategory if it has matching products
            guard !filteredProducts.isEmpty else { return nil }

            var filteredSubcategory = subcategory
            filteredSubcategory.products = filteredProducts
            return filteredSubcategory
        }
    }


    // MARK: - Body

    var body: some View {
        ZStack {
            if productService.isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(localization.localized("products.loading"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage = productService.errorMessage, productService.allProducts.isEmpty {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(localization.localized("products.load_error"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Button(localization.localized("delivery.retry")) {
                        Task {
                            await productService.loadProducts()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Subcategory filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // "All" button
                            CategoryCircleChip(
                                title: localization.localized("products.all"),
                                icon: "square.grid.2x2.fill",
                                color: .accentColor,
                                isSelected: selectedSubcategory == nil
                            ) {
                                selectedSubcategory = nil
                            }

                            // Individual subcategory filter buttons
                            let subcategories = productService.categories.first?.subcategories ?? []
                            ForEach(Array(subcategories.enumerated()), id: \.element.id) { index, subcategory in
                                CategoryCircleChip(
                                    title: subcategory.name,
                                    icon: subcategory.icon,
                                    color: Self.categoryColors[index % Self.categoryColors.count],
                                    isSelected: selectedSubcategory?.id == subcategory.id
                                ) {
                                    selectedSubcategory = subcategory
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))

                    // Products organized by subcategory sections
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: []) {
                            // Empty state when no search results
                            if displayedSubcategories.isEmpty && !searchText.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                    Text(localization.localized("search.no_results"))
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            }

                            ForEach(displayedSubcategories) { subcategory in
                                VStack(alignment: .leading, spacing: 16) {
                                    // Subcategory Header
                                    Text(subcategory.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)

                                    // Products Grid for this subcategory
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(subcategory.products) { product in
                                            GiftProductCard(
                                                product: product,
                                                quantity: cart.quantity(for: product),
                                                onAdd: {
                                                    cart.addProduct(product)
                                                },
                                                onRemove: {
                                                    let currentQty = cart.quantity(for: product)
                                                    cart.updateQuantity(for: product, quantity: currentQty - 1)
                                                },
                                                onTap: {
                                                    selectedProductForDetail = product
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await productService.loadProducts()
                    }
                }
            }
        }
        .navigationTitle(localization.localized("products.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Cart button with badge
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    if !cart.isEmpty {
                        navigateToSummary = true
                    }
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16))

                        if cart.itemCount > 0 {
                            Text("\(cart.itemCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -6)
                        }
                    }
                    .frame(width: 30, height: 30)
                }
                .disabled(cart.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom summary bar (shown when cart has items)
            if !cart.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.plural("items", count: cart.itemCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(cart.formattedTotalPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    Button(action: {
                        navigateToSummary = true
                    }) {
                        HStack {
                            Text(localization.localized("products.view_box"))
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            }
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            BoxSummaryView()
        }
        .sheet(item: $selectedProductForDetail) { product in
            ProductDetailView(
                product: product,
                quantity: cart.quantity(for: product),
                onAdd: {
                    cart.addProduct(product)
                },
                onRemove: {
                    let currentQty = cart.quantity(for: product)
                    cart.updateQuantity(for: product, quantity: currentQty - 1)
                }
            )
        }
        .task {
            // Load products on first appearance
            if productService.allProducts.isEmpty {
                await productService.loadProducts()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProductSelectionView()
            .environment(CartViewModel())
    }
}
