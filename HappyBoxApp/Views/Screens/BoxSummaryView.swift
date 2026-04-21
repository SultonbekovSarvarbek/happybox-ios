//
//  BoxSummaryView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Box summary and review screen
struct BoxSummaryView: View {
    // MARK: - Properties

    @Environment(CartViewModel.self) private var cart
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDelivery = false
    @State private var previousItemCount = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Cart items list
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text(localization.localized("box.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text(localization.plural("items", count: cart.itemCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                    // Cart items
                    ForEach(cart.cartItems) { item in
                        CartItemRow(
                            item: item,
                            onIncrease: {
                                cart.addProduct(item.product)
                            },
                            onDecrease: {
                                cart.updateQuantity(
                                    for: item.product,
                                    quantity: item.quantity - 1
                                )
                            },
                            onRemove: {
                                cart.removeProduct(item.product)
                            }
                        )
                    }

                    // Empty state
                    if cart.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "cart")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                            Text(localization.localized("box.empty"))
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Button(localization.localized("box.add_items")) {
                                dismiss()
                            }
                        }
                        .padding(40)
                    }
                }
            }

            Divider()

            // Total and Continue button
            if !cart.isEmpty {
                VStack(spacing: 16) {
                    // Products subtotal
                    HStack {
                        Text(localization.localized("box.products_section"))
                            .font(.body)
                        Spacer()
                        Text(cart.formattedTotalPrice)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    // Service fee
                    HStack {
                        Text(localization.localized("box.service_fee"))
                            .font(.body)
                        Spacer()
                        Text(Constants.Pricing.formattedServiceFee)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    // Delivery fee
                    HStack {
                        Text(localization.localized("box.delivery"))
                            .font(.body)
                        Spacer()
                        Text(Constants.Pricing.formattedDeliveryFee)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    Divider()

                    // Total price
                    HStack {
                        Text(localization.localized("box.total"))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(cart.formattedGrandTotal)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }

                    // Continue button
                    GiftPrimaryButton(localization.localized("delivery.title"), icon: "arrow.right") {
                        navigateToDelivery = true
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(localization.localized("box.view_box"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDelivery) {
            DeliveryFormView()
        }
        .onAppear {
            previousItemCount = cart.itemCount
        }
        .onChange(of: cart.itemCount) { oldValue, newValue in
            // Auto-dismiss when cart becomes empty after having items
            // (indicates successful order completion)
            if previousItemCount > 0 && newValue == 0 {
                dismiss()
            }
            previousItemCount = newValue
        }
    }
}

// MARK: - Cart Item Row Component

struct CartItemRow: View {
    @Environment(LocalizationManager.self) private var localization
    let item: CartItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Product image - EXACT pattern from GiftProductCard (using 300x300 like GiftProductCard)
            Group {
                if let imageURL = item.product.imageURL,
                   let url = URL(string: Constants.Image.processURL(imageURL, resolution: Constants.Image.thumbnailResolution)) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                        case .failure:
                            Image(systemName: item.product.imageName)
                                .font(.system(size: 30))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                                .frame(width: 60, height: 60)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: item.product.imageName)
                        .font(.system(size: 30))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                        .frame(width: 60, height: 60)
                }
            }
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)

                Text(item.product.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(item.formattedTotalPrice)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()

            // Quantity controls
            VStack(spacing: 8) {
                // Increase button
                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                }

                // Quantity display
                Text("\(item.quantity)")
                    .font(.system(size: 16, weight: .bold))
                    .frame(minWidth: 30)

                // Decrease button
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onRemove) {
                Label(localization.localized("box.delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BoxSummaryView()
            .environment({
                let cart = CartViewModel()
                if let product = ProductDataService.shared.allProducts.first {
                    cart.addProduct(product)
                }
                return cart
            }())
    }
}
