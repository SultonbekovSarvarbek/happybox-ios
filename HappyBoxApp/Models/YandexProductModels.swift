//
//  YandexProductModels.swift
//  HappyBoxApp
//
//  Created by Claude Code on 02/01/26.
//

import Foundation

/// Root structure for Yandex product catalog JSON
struct YandexProductCatalog: Decodable {
    let categoryGroup: CategoryGroup
    let categories: [CategoryContainer]
}

/// Category group information
struct CategoryGroup: Decodable {
    let id: String
    let title: String
}

/// Container for category data
struct CategoryContainer: Decodable {
    let id: String
    let value: CategoryValue
    let items: [SubcategoryContainer]
}

/// Category value details
struct CategoryValue: Decodable {
    let id: String
    let deepLink: String
    let title: String
    let available: Bool
    let type: String
}

/// Container for subcategory data
struct SubcategoryContainer: Decodable {
    let id: String
    let value: SubcategoryValue
    let items: [ProductContainer]
}

/// Subcategory value details
struct SubcategoryValue: Decodable {
    let id: String
    let title: String
    let available: Bool
    let type: String
}

/// Container for product data
struct ProductContainer: Decodable {
    let id: String
    let value: ProductValue
}

/// Product details from JSON
struct ProductValue: Decodable {
    let id: String
    let deepLink: String
    let title: String
    let longTitle: String?
    let amount: String
    let available: Bool
    let pricing: Pricing
    let discountPricing: DiscountPricing?
    let snippetImage: SnippetImage
    let quantityLimit: String
    let options: ProductOptions?
    let type: String
}

/// Pricing information
struct Pricing: Decodable {
    let price: String
    let priceTemplate: String
}

/// Discount pricing information (optional)
struct DiscountPricing: Decodable {
    let price: String
    let priceTemplate: String
    let discountLabel: String
}

/// Product image information
struct SnippetImage: Decodable {
    let url: String
}

/// Product options and attributes
struct ProductOptions: Decodable {
    let attributes: ProductAttributes?
}

/// Product attributes (allergens, ingredients, etc.)
struct ProductAttributes: Decodable {
    let mainAllergens: [String]?
    let importantIngredients: [String]?
}
