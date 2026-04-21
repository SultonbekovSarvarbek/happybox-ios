//
//  GiftProduct.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation

/// Hierarchical category structure for products
struct GiftCategory: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let subcategories: [GiftSubcategory]
    let icon: String

    /// All products across all subcategories in this category
    var allProducts: [GiftProduct] {
        subcategories.flatMap { $0.products }
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GiftCategory, rhs: GiftCategory) -> Bool {
        lhs.id == rhs.id
    }
}

/// Subcategory within a main category
struct GiftSubcategory: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    var products: [GiftProduct]

    /// SF Symbol icon based on subcategory name
    var icon: String {
        let lowercased = name.lowercased()
        switch true {
        case lowercased.contains("шоколад") && !lowercased.contains("батончик"):
            return "square.stack.fill"
        case lowercased.contains("конфет"):
            return "seal.fill"  // Looks like wrapped candy
        case lowercased.contains("батончик"):
            return "rectangle.roundedtop.fill"
        case lowercased.contains("протеин"):
            return "dumbbell.fill"
        case lowercased.contains("злаков") || lowercased.contains("фрукт"):
            return "leaf.fill"
        case lowercased.contains("игрушк"):
            return "teddybear.fill"
        default:
            return "circle.fill"
        }
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GiftSubcategory, rhs: GiftSubcategory) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a product that can be added to a gift box
struct GiftProduct: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let price: Double
    let imageName: String // SF Symbol name for fallback
    let imageURL: String? // Photo URL from server
    let subcategory: GiftSubcategory
    let description: String
    let amount: String? // e.g., "30 г"
    let allergens: [String]? // For future use
    let quantityLimit: Int? // For future use

    /// Backward compatibility - returns subcategory name
    var category: String {
        subcategory.name
    }

    /// Formatted price string for display
    var formattedPrice: String {
        let sumValue = Int(price * 1000)  // Convert back to actual сум
        return "\(sumValue.formatted()) сум"
    }

    /// Convenience initializer with optional fields
    init(
        id: String,
        name: String,
        price: Double,
        imageName: String,
        imageURL: String? = nil,
        subcategory: GiftSubcategory,
        description: String,
        amount: String? = nil,
        allergens: [String]? = nil,
        quantityLimit: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageName = imageName
        self.imageURL = imageURL
        self.subcategory = subcategory
        self.description = description
        self.amount = amount
        self.allergens = allergens
        self.quantityLimit = quantityLimit
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GiftProduct, rhs: GiftProduct) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents an item in the shopping cart with quantity
struct CartItem: Identifiable {
    let id: UUID
    let product: GiftProduct
    var quantity: Int

    /// Total price for this cart item (price × quantity)
    var totalPrice: Double {
        product.price * Double(quantity)
    }

    /// Formatted total price for display
    var formattedTotalPrice: String {
        let sumValue = Int(totalPrice * 1000)  // Convert back to actual сум
        return "\(sumValue.formatted()) сум"
    }

    init(product: GiftProduct, quantity: Int = 1) {
        self.id = UUID()
        self.product = product
        self.quantity = quantity
    }
}

/// Customer delivery and contact information
struct DeliveryInfo {
    var recipientName: String = ""
    var phoneNumber: String = ""
    var deliveryDate: String = ""  // e.g., "Сегодня", "Завтра", "15 января"
    var deliveryTime: String = ""  // e.g., "10:00", "14:00", "18:00"
    var message: String = ""

    /// Formatted delivery date and time for display
    var formattedDeliveryDateTime: String {
        if deliveryDate.isEmpty || deliveryTime.isEmpty {
            return ""
        }
        return "\(deliveryDate) \(deliveryTime)"
    }

    /// Check if phone number has valid format (digits only, 9-15 chars, allows leading +)
    var isPhoneValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 9 && digits.count <= 15
    }

    /// Validates that all required fields are filled with valid data
    var isValid: Bool {
        !recipientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isPhoneValid &&
        !deliveryDate.isEmpty &&
        !deliveryTime.isEmpty
    }
}
