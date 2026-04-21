//
//  PurchaseRequest.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import Foundation

// MARK: - Flexible decodable types (handle both plain string and object)

/// Decodes either `"PAID"` or `{ "value": "PAID", "label": "..." }`
struct FlexStatus: Decodable, Sendable {
    let value: String?
    init(from decoder: Decoder) throws {
        if let s = try? decoder.singleValueContainer().decode(String.self) {
            value = s
        } else {
            struct Obj: Decodable { let value: String? }
            value = (try? Obj(from: decoder))?.value
        }
    }
}

/// Decodes either `"Ташкент"` or `{ "id": 1, "name": "Ташкент" }`
struct FlexNamed: Decodable, Sendable {
    let name: String?
    init(from decoder: Decoder) throws {
        if let s = try? decoder.singleValueContainer().decode(String.self) {
            name = s
        } else {
            struct Obj: Decodable { let name: String? }
            name = (try? Obj(from: decoder))?.name
        }
    }
}

/// Decodes either `"gifts"` or `{ "id": 2, "value": "gifts", "label": "Подарки" }`
struct FlexLabeled: Decodable, Sendable {
    let value: String?
    init(from decoder: Decoder) throws {
        if let s = try? decoder.singleValueContainer().decode(String.self) {
            value = s
        } else {
            struct Obj: Decodable { let value: String? }
            value = (try? Obj(from: decoder))?.value
        }
    }
}

// MARK: - PurchaseRequest

struct PurchaseRequest: Decodable, Identifiable, Sendable {
    let id: String
    let status: FlexStatus?
    let createdAt: String?
    let certificate: PurchaseCertificate?
    let voucher: Voucher?

    struct Voucher: Decodable, Sendable {
        let id: String?
        let code: String?
        let isRedeemed: Bool?
        let originalOwnerId: String?
        let currentOwnerId: String?
    }

    var voucherCode: String? { voucher?.code }
    var voucherId: String? { voucher?.id }

    var isPaid: Bool {
        (status?.value ?? "").uppercased() == "PAID"
    }

    var isRedeemed: Bool {
        voucher?.isRedeemed == true
    }

    /// Ваучер был передан другому человеку (currentOwner != originalOwner)
    var isTransferred: Bool {
        guard let v = voucher,
              let original = v.originalOwnerId,
              let current = v.currentOwnerId else { return false }
        return original != current
    }

    struct PurchaseCertificate: Decodable, Sendable {
        let id: String?
        let name: String?
        let description: String?
        let price: String?
        let validDays: Int?
        let imageUrl: String?
        let instagram: String?
        let phone: String?
        let type: FlexLabeled?
        let category: FlexLabeled?
        let subcategory: FlexLabeled?
        let city: FlexNamed?
        let district: FlexNamed?
        let partner: PurchasePartner?

        struct PurchasePartner: Decodable, Sendable {
            let id: String?
            let name: String?
            let phone: String?
        }

        var formattedPrice: String {
            guard let p = price, let amount = Int(p) else { return "" }
            return "\(amount.formatted()) сум"
        }

        var locationString: String? {
            let c = city?.name
            let d = district?.name
            switch (c, d) {
            case let (c?, d?): return "\(c), \(d)"
            case let (c?, nil): return c
            case let (nil, d?): return d
            default: return nil
            }
        }
    }

    var localizedStatus: String {
        if isPaid && isRedeemed { return "Использован" }
        if isPaid && isTransferred { return "Подарен" }
        switch (status?.value ?? "").uppercased() {
        case "NEW":       return "В обработке"
        case "PAID":      return "Подтверждён"
        case "CANCELLED": return "Отменён"
        default:          return "В обработке"
        }
    }

    var formattedDate: String {
        guard let createdAt else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        if let date = iso.date(from: createdAt) ?? fallback.date(from: createdAt) {
            return formatter.string(from: date)
        }
        return createdAt
    }
}
