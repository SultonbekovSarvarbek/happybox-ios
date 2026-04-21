//
//  GiftProductCard.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Reusable product card component for gift selection
struct GiftProductCard: View {
    // MARK: - Properties

    @Environment(LocalizationManager.self) private var localization
    let product: GiftProduct
    let quantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image with Category and Amount Badges
            ZStack(alignment: .topLeading) {
                // Product Image - URL or SF Symbol fallback
                Group {
                    if let imageURL = product.imageURL, !imageURL.isEmpty {
                        let processedURL = Constants.Image.processURL(imageURL)

                        if let url = URL(string: processedURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                case .failure:
                                    Image(systemName: product.imageName)
                                        .font(.system(size: 50))
                                        .foregroundStyle(Color.accentColor.opacity(0.8))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: product.imageName)
                                .font(.system(size: 50))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                        }
                    } else {
                        // Fallback to SF Symbol
                        Image(systemName: product.imageName)
                            .font(.system(size: 50))
                            .foregroundStyle(Color.accentColor.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                    }
                }
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            }
            .overlay(alignment: .topTrailing) {
                // Amount badge (top-right) if available
                if let amount = product.amount {
                    Text(amount)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.8))
                        .foregroundStyle(.white)
                        .cornerRadius(6)
                        .padding(8)
                }
            }
            .onTapGesture {
                onTap()
            }

            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(product.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            .onTapGesture {
                onTap()
            }

            // Add/Remove Controls
            if quantity > 0 {
                // Quantity controls (when product is in cart)
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(quantity)")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(minWidth: 30)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                // Add button (when product not in cart)
                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text(localization.localized("product_card.add"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        // Product not in cart
        GiftProductCard(
            product: ProductDataService.shared.allProducts.first!,
            quantity: 0,
            onAdd: {},
            onRemove: {},
            onTap: {}
        )
        .frame(width: 180)

        // Product in cart
        GiftProductCard(
            product: ProductDataService.shared.allProducts.first!,
            quantity: 2,
            onAdd: {},
            onRemove: {},
            onTap: {}
        )
        .frame(width: 180)
    }
    .padding()
}
