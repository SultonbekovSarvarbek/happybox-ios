//
//  CartViewModel.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation
import SwiftUI
import Observation

/// Lightweight struct for persisting cart items to UserDefaults
private struct PersistedCartItem: Codable {
    let productId: String
    let quantity: Int
}

/// Manages shopping cart state and order submission
/// Uses @Observable for modern SwiftUI state management (iOS 17+)
@Observable
class CartViewModel {
    // MARK: - Properties

    /// Items currently in the cart
    var cartItems: [CartItem] = [] {
        didSet { persistCart() }
    }

    /// Customer delivery and contact information
    var deliveryInfo: DeliveryInfo = DeliveryInfo()

    /// Additional fees (from shared constants)
    private var serviceFee: Double { Constants.Pricing.serviceFee }
    private var deliveryFee: Double { Constants.Pricing.deliveryFee }

    // MARK: - Order Sending State

    /// Indicates if order is currently being sent
    var isSendingOrder: Bool = false

    /// Indicates if order was successfully sent
    var orderSentSuccessfully: Bool = false

    /// Error message that occurred during order sending
    var orderError: String?

    /// User-friendly error message for display
    var orderErrorMessage: String {
        orderError ?? LocalizationManager.shared.localized("error.unknown")
    }

    // MARK: - Computed Properties

    /// Total price of all items in cart
    var totalPrice: Double {
        cartItems.reduce(0) { $0 + $1.totalPrice }
    }

    /// Formatted total price for display
    var formattedTotalPrice: String {
        let sumValue = Int(totalPrice * 1000)  // Convert back to actual сум
        return "\(sumValue.formatted()) \(LocalizationManager.shared.localized("currency.symbol"))"
    }

    /// Grand total including service and delivery fees
    var grandTotal: Double {
        totalPrice + serviceFee + deliveryFee
    }

    /// Formatted grand total for display
    var formattedGrandTotal: String {
        let sumValue = Int(grandTotal * 1000)  // Convert back to actual сум
        return "\(sumValue.formatted()) \(LocalizationManager.shared.localized("currency.symbol"))"
    }

    /// Total number of items in cart (sum of quantities)
    var itemCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    /// Check if cart is empty
    var isEmpty: Bool {
        cartItems.isEmpty
    }

    // MARK: - Cart Management Methods

    /// Add a product to the cart or increase quantity if already exists
    /// - Parameter product: The product to add
    func addProduct(_ product: GiftProduct) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            // Product already in cart, increase quantity
            cartItems[index].quantity += 1
        } else {
            // Add new product to cart
            let cartItem = CartItem(product: product, quantity: 1)
            cartItems.append(cartItem)
        }
    }

    /// Remove a product completely from the cart
    /// - Parameter product: The product to remove
    func removeProduct(_ product: GiftProduct) {
        cartItems.removeAll { $0.product.id == product.id }
    }

    /// Update the quantity of a specific product in the cart
    /// - Parameters:
    ///   - product: The product to update
    ///   - quantity: New quantity (removes item if quantity is 0)
    func updateQuantity(for product: GiftProduct, quantity: Int) {
        if quantity <= 0 {
            removeProduct(product)
            return
        }

        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[index].quantity = quantity
        }
    }

    /// Get quantity of a specific product in cart
    /// - Parameter product: The product to check
    /// - Returns: Quantity in cart (0 if not in cart)
    func quantity(for product: GiftProduct) -> Int {
        cartItems.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }

    /// Clear all items from the cart
    func clearCart() {
        cartItems.removeAll()
    }

    // MARK: - Order Submission

    /// Send order to backend API
    /// TODO: implement with POST /orders endpoint
    @MainActor
    func sendOrder() async {
        isSendingOrder = true
        orderSentSuccessfully = false
        orderError = nil

        do {
            // TODO: replace with real backend API call
            // try await OrderService.shared.submitOrder(cartItems: cartItems, deliveryInfo: deliveryInfo)
            try await Task.sleep(for: .seconds(1)) // placeholder
            orderSentSuccessfully = true
        } catch {
            orderError = error.localizedDescription
        }

        isSendingOrder = false
    }

    /// Reset order sending state
    /// Call this after user dismisses success/error alert
    func resetOrderState() {
        orderSentSuccessfully = false
        orderError = nil
    }

    // MARK: - Cart Persistence

    private static let cartKey = "happybox.cart.items"

    private func persistCart() {
        let items = cartItems.map { PersistedCartItem(productId: $0.product.id, quantity: $0.quantity) }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.cartKey)
        }
    }

    /// Restore cart from UserDefaults after products are loaded
    func restoreCart(from products: [GiftProduct]) {
        guard let data = UserDefaults.standard.data(forKey: Self.cartKey),
              let saved = try? JSONDecoder().decode([PersistedCartItem].self, from: data) else {
            return
        }

        let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        var restored: [CartItem] = []
        for item in saved {
            if let product = productMap[item.productId] {
                restored.append(CartItem(product: product, quantity: item.quantity))
            }
        }
        // Set directly to backing storage to avoid triggering didSet -> persistCart loop
        if !restored.isEmpty {
            cartItems = restored
        }
    }
}
