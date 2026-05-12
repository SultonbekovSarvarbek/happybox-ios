//
//  MobileCardModels.swift
//  HappyBoxApp
//

import Foundation

// MARK: - Card Category

struct MobileCardCategory: Decodable, Identifiable, Sendable {
    let id: Int
    let value: String
    let label: String

    var asCertificateCategory: CertificateCategory? {
        CertificateCategory(rawValue: value.lowercased())
    }
}

// MARK: - Card List Item (GET /mobile/cards)

struct MobileCard: Decodable, Identifiable, Sendable {
    let id: String
    let partnerId: String?
    let name: String
    let photo: String?
    let instagram: String?
    let description: String?
    let notes: [String]?
    let certificatesCount: Int?
    let categories: [MobileCardCategory]?
    let locations: [String]?
}

// MARK: - Paginated response wrapper

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let meta: PaginationMeta?

    struct PaginationMeta: Decodable {
        let total: Int?
        let page: Int?
        let limit: Int?
        let totalPages: Int?
    }
}

// MARK: - Card Detail (GET /mobile/cards/:id)

struct MobileCardDetail: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let photo: String?
    let instagram: String?
    let description: String?
    let notes: [String]?
    let certificates: [MobileCardCertificate]
}

// MARK: - Certificate inside a Card

struct MobileCardCertificate: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String?
    let price: String
    let validDays: Int?
    let phone: String?
    let instagram: String?
    let images: [CardCertificateImage]?
    let type: CertType?
    let city: CertCity?
    let district: CertDistrict?
    let category: MobileCardCategory?
    let isActive: Bool

    struct CardCertificateImage: Decodable, Sendable {
        let id: String?
        let url: String?
    }

    struct CertType: Decodable, Sendable {
        let id: Int?
        let value: String?
        let label: String?
    }

    struct CertCity: Decodable, Sendable {
        let id: Int?
        let name: String?
    }

    struct CertDistrict: Decodable, Sendable {
        let id: Int?
        let name: String?
    }
}

// MARK: - Mapping to Certificate

extension MobileCardCertificate {
    func toCertificate(partnerName: String, baseURL: String) -> Certificate {
        let priceInt = Int(price) ?? 0

        let allImageURLs: [String] = (images ?? []).compactMap { img in
            guard let url = img.url else { return nil }
            return url.hasPrefix("http") ? url : baseURL + url
        }

        let expiresAt = (validDays ?? 0) > 0
            ? Calendar.current.date(byAdding: .day, value: validDays!, to: Date())
            : nil

        let certCategory = category?.asCertificateCategory ?? .care

        let instagramHandle = instagram?
            .replacingOccurrences(of: "@", with: "")
            .components(separatedBy: "|").first?
            .trimmingCharacters(in: .whitespaces)

        let districtName = district?.name ?? ""
        let tashkentDistrict = districtName.isEmpty
            ? .mirobod
            : TashkentDistrict.from(backendName: districtName)

        return Certificate(
            apiId: id,
            title: name,
            description: description ?? "",
            location: partnerName,
            locationDetail: districtName,
            priceMin: priceInt,
            priceMax: priceInt,
            category: certCategory,
            imageURLs: allImageURLs,
            instagramHandle: instagramHandle,
            expiresAt: expiresAt,
            district: tashkentDistrict,
            districtName: districtName
        )
    }
}
