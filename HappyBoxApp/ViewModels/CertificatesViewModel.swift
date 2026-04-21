//
//  CertificatesViewModel.swift
//  HappyBoxApp
//

import Foundation
import Observation

@Observable
class CertificatesViewModel {
    var cards: [MobileCard] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Current location filter sent to API
    private(set) var selectedCityId: Int? = nil
    private(set) var selectedDistrictId: Int? = nil

    @MainActor
    func load(cityId: Int? = nil, districtId: Int? = nil) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        selectedCityId = cityId
        selectedDistrictId = districtId
        do {
            cards = try await CertificateService.shared.fetchCards(cityId: cityId, districtId: districtId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private static let hiddenCategories: Set<CertificateCategory> = [
        .auto, .kids, .home, .travel, .entertainment, .fitness, .food, .education
    ]

    var availableCategories: [CertificateCategory] {
        CertificateCategory.allCases.filter { !Self.hiddenCategories.contains($0) }
    }

    func filtered(by category: CertificateCategory?) -> [MobileCard] {
        guard let category else { return cards }
        return cards.filter { card in
            (card.categories ?? []).contains { $0.asCertificateCategory == category }
        }
    }
}
