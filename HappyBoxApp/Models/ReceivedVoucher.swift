//
//  ReceivedVoucher.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 28/02/26.
//

import Foundation

struct ReceivedVoucher: Decodable, Identifiable, Sendable {
    let id: String
    let code: String?
    let isRedeemed: Bool?
    let redeemedAt: String?
    let createdAt: String?
    let originalOwner: VoucherOwner?
    let purchaseRequest: VoucherPurchaseRequest?

    // Convenience accessor
    var certificate: VoucherCertificate? { purchaseRequest?.certificate }

    struct VoucherOwner: Decodable, Sendable {
        let id: String?
        let username: String?
        let firstName: String?

        var displayName: String {
            let name = firstName ?? ""
            let handle = username.map { "@\($0.replacingOccurrences(of: "@", with: ""))" } ?? ""
            if !name.isEmpty && !handle.isEmpty { return "\(name) (\(handle))" }
            return name.isEmpty ? handle : name
        }
    }

    struct VoucherPurchaseRequest: Decodable, Sendable {
        let id: String?
        let certificate: VoucherCertificate?
    }

    struct VoucherCertificate: Decodable, Sendable {
        let id: String?
        let name: String?
        let description: String?
        let price: String?
        let validDays: Int?
        let imageUrl: String?
        let instagram: String?
        let type: LabeledValue?
        let category: LabeledValue?
        let subcategory: LabeledValue?
        let city: NamedObject?
        let district: NamedObject?
        let partner: VoucherPartner?

        struct LabeledValue: Decodable, Sendable {
            let id: Int?
            let value: String?
            let label: String?
        }

        struct NamedObject: Decodable, Sendable {
            let id: Int?
            let name: String?
        }

        struct VoucherPartner: Decodable, Sendable {
            let id: String?
            let name: String?
        }

        var formattedPrice: String {
            guard let p = price, let amount = Int(p) else { return "" }
            return "\(amount.formatted()) сум"
        }

        var locationString: String? {
            let cityName = city?.name
            let districtName = district?.name
            switch (cityName, districtName) {
            case let (c?, d?): return "\(c), \(d)"
            case let (c?, nil): return c
            case let (nil, d?): return d
            default: return nil
            }
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
