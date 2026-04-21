//
//  CustomCertificateModels.swift
//  HappyBoxApp
//

import Foundation

// MARK: - Partner Service Item (GET /mobile/cards/:id/services)

struct PartnerServiceItem: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String?
    let price: String

    var priceInt: Int { Int(price) ?? 0 }

    var formattedPrice: String {
        "\(priceInt.formatted()) сум"
    }
}

// MARK: - Custom Certificate Response (POST /mobile/certificates/custom → 201)

struct CustomCertificateResponse: Decodable, Sendable {
    let id: String
    let name: String?
    let type: String?
    let totalPrice: Int?
    let validDays: Int?
    let partnerCardId: String?
    let services: [CustomServiceItem]?
}

// MARK: - Custom Certificate Detail (GET /mobile/certificates/custom/:id)

struct CustomCertificateDetail: Decodable, Sendable {
    let id: String
    let name: String?
    let type: String?
    let totalPrice: Int?
    let validDays: Int?
    let partnerCard: PartnerCardRef?
    let services: [CustomServiceItem]?

    struct PartnerCardRef: Decodable, Sendable {
        let id: String
        let name: String?
        let photo: String?
    }
}

// MARK: - Custom Service Item (shared between response types)

struct CustomServiceItem: Decodable, Identifiable, Sendable {
    private let itemId: String?
    let name: String
    let description: String?
    let price: Int?

    var id: String { itemId ?? name }

    var formattedPrice: String {
        guard let p = price else { return "" }
        return "\(p.formatted()) сум"
    }

    enum CodingKeys: String, CodingKey {
        case itemId = "id"
        case name, description, price
    }
}
