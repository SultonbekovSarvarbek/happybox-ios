//
//  ProductDataService.swift
//  HappyBoxApp
//
//  Created by Claude Code on 02/01/26.
//

import Foundation
import Observation

/// Service for loading and managing product data
@Observable
class ProductDataService {
    // MARK: - Properties

    /// Hierarchical category structure
    var categories: [GiftCategory] = []

    /// All products across all categories
    var allProducts: [GiftProduct] = []

    /// Loading state indicator
    var isLoading: Bool = false

    /// Error message if loading fails
    var errorMessage: String?

    // MARK: - Singleton

    static let shared = ProductDataService()

    private init() {}

    // MARK: - Public Methods

    /// Load products from JSON bundle
    func loadProducts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let jsonProducts = try await loadJSONFromBundle()
            let hierarchy = buildCategoryHierarchy(products: jsonProducts)

            await MainActor.run {
                self.categories = hierarchy
                self.allProducts = jsonProducts
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Private Methods

    /// Load and parse JSON from app bundle
    private func loadJSONFromBundle() async throws -> [GiftProduct] {
        guard let url = Bundle.main.url(forResource: "products", withExtension: "json") else {
            throw ProductDataError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let catalog = try decoder.decode(YandexProductCatalog.self, from: data)

        return convertToGiftProducts(catalog: catalog)
    }

    /// Convert Yandex JSON models to GiftProduct array
    private func convertToGiftProducts(catalog: YandexProductCatalog) -> [GiftProduct] {
        var products: [GiftProduct] = []

        for category in catalog.categories {
            for subcategoryContainer in category.items {
                guard subcategoryContainer.value.type == "subcategory" else { continue }

                let subcategory = GiftSubcategory(
                    id: subcategoryContainer.id,
                    name: subcategoryContainer.value.title,
                    products: []
                )

                for productContainer in subcategoryContainer.items {
                    guard productContainer.value.type == "good" else { continue }

                    let val = productContainer.value

                    guard let priceInt = Int(val.pricing.price) else { continue }
                    let price = Double(priceInt) / 1000.0

                    let quantityLimit = Int(val.quantityLimit)

                    let product = GiftProduct(
                        id: val.id,
                        name: val.title,
                        price: price,
                        imageName: determineIconName(for: subcategory.name),
                        imageURL: val.snippetImage.url,
                        subcategory: subcategory,
                        description: val.longTitle ?? val.title,
                        amount: val.amount,
                        allergens: val.options?.attributes?.mainAllergens,
                        quantityLimit: quantityLimit
                    )

                    products.append(product)
                }
            }
        }

        return products
    }

    /// Build category hierarchy from flat product list
    private func buildCategoryHierarchy(products: [GiftProduct]) -> [GiftCategory] {
        var subcategoryMap: [String: GiftSubcategory] = [:]

        for product in products {
            let subcatId = product.subcategory.id
            if var existing = subcategoryMap[subcatId] {
                existing.products.append(product)
                subcategoryMap[subcatId] = existing
            } else {
                var newSubcat = product.subcategory
                newSubcat.products = [product]
                subcategoryMap[subcatId] = newSubcat
            }
        }

        let sortedSubcategories = Array(subcategoryMap.values).sorted { $0.name < $1.name }

        let mainCategory = GiftCategory(
            id: "sweets_and_snacks",
            name: "Сладкое и снеки",
            subcategories: sortedSubcategories,
            icon: "square.grid.2x2.fill"
        )

        return [mainCategory]
    }

    /// Determine SF Symbol icon based on subcategory name
    private func determineIconName(for subcategoryName: String) -> String {
        let lowercased = subcategoryName.lowercased()
        switch true {
        case lowercased.contains("шоколад"):
            return "square.fill"
        case lowercased.contains("конфет"):
            return "gift.fill"
        case lowercased.contains("батончик"):
            return "rectangle.fill"
        case lowercased.contains("чипс") || lowercased.contains("снек"):
            return "bag.fill"
        default:
            return "circle.fill"
        }
    }
}

/// Errors that can occur during product data loading
enum ProductDataError: Error {
    case fileNotFound
    case parsingFailed
}
