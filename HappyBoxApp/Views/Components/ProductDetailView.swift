//
//  ProductDetailView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Full product detail view shown in a sheet
struct ProductDetailView: View {
    // MARK: - Properties

    let product: GiftProduct
    let quantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localization

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    ZStack(alignment: .topLeading) {
                        Group {
                            if let imageURL = product.imageURL,
                               let url = URL(string: Constants.Image.processURL(imageURL)) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 300)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 300)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: product.imageName)
                                            .font(.system(size: 100))
                                            .foregroundStyle(Color.accentColor.opacity(0.8))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 300)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: product.imageName)
                                    .font(.system(size: 100))
                                    .foregroundStyle(Color.accentColor.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                            }
                        }
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(16)

                        // Category badge
                        Text(product.category)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                            .padding(12)
                    }
                    .overlay(alignment: .topTrailing) {
                        // Amount badge if available
                        if let amount = product.amount {
                            Text(amount)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.8))
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                                .padding(12)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        // Product Name
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        // Price
                        Text(product.formattedPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)

                        // Description
                        if !product.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localization.localized("product_detail.description"))
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text(product.description)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(localization.localized("product_detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("product_detail.close")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Add to cart controls
                VStack(spacing: 0) {
                    Divider()

                    if quantity > 0 {
                        // Quantity controls (when product is in cart)
                        HStack(spacing: 16) {
                            Button(action: onRemove) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.secondary)
                            }

                            VStack(spacing: 4) {
                                Text(localization.localized("product_detail.in_box"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(quantity)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Button(action: onAdd) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        // Add button (when product not in cart)
                        Button(action: onAdd) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text(localization.localized("product_detail.add_to_box"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProductDetailView(
        product: ProductDataService.shared.allProducts.first!,
        quantity: 0,
        onAdd: {},
        onRemove: {}
    )
}
