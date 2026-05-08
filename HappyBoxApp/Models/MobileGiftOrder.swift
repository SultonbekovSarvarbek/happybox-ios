//
//  MobileGiftOrder.swift
//  HappyBoxApp
//

import Foundation

struct MobileGiftOrder: Decodable, Identifiable, Sendable {
    let id: String
    let shortCode: String
    let giftType: String
    let isPaid: Bool
    let isBalanceBased: Bool
    let isRedeemed: Bool
    let totalAmount: Double
    let remainingAmount: Double?
    let recipientName: String
    let recipientPhone: String
    let senderName: String
    let senderPhone: String
    let partner: GiftOrderPartner?
    let certificate: GiftOrderCert?
    let redemptions: [GiftOrderRedemption]
    let createdAt: String

    struct GiftOrderPartner: Decodable, Sendable {
        let id: String?
        let name: String?
        let slug: String?
        let photo: String?
        let instagram: String?
    }

    struct GiftOrderCert: Decodable, Sendable {
        let id: String?
        let name: String?
        let description: String?
    }

    struct GiftOrderRedemption: Decodable, Identifiable, Sendable {
        let id: String
        let amount: Double
        let note: String?
        let createdAt: String

        var formattedAmount: String {
            "\(Int(amount).formatted()) сум"
        }

        var formattedDate: String {
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

    var formattedTotalAmount: String { "\(Int(totalAmount).formatted()) сум" }

    var formattedRemainingAmount: String? {
        guard let r = remainingAmount else { return nil }
        return "\(Int(r).formatted()) сум"
    }

    var formattedDate: String {
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
