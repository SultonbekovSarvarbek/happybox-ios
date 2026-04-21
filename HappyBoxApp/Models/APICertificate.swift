//
//  APICertificate.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation

/// Raw backend certificate model decoded from GET /mobile/certificates
struct APICertificate: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let price: String
    let validDays: Int
    let instagram: String?
    let imageUrl: String?
    let images: [CertificateImage]?
    let isActive: Bool
    let partner: Partner
    let category: Category
    let subcategory: Category?
    let city: City
    let district: District

    struct CertificateImage: Decodable {
        let id: String
        let url: String
    }

    struct Partner: Decodable {
        let id: String
        let name: String
    }

    struct Category: Decodable {
        let id: Int
        let value: String
        let label: String
    }

    struct City: Decodable {
        let id: Int
        let name: String
    }

    struct District: Decodable {
        let id: Int
        let name: String
    }
}

// MARK: - Mapping to Certificate

extension APICertificate {
    func toCertificate(baseURL: String) -> Certificate {
        let price = Int(self.price) ?? 0

        let rawImageURL = imageUrl ?? images?.first?.url
        let imageFullURL = rawImageURL.map { path in
            path.hasPrefix("http") ? path : baseURL + path
        }

        let allImageURLs: [String] = (images ?? []).map { img in
            img.url.hasPrefix("http") ? img.url : baseURL + img.url
        }

        let expiresAt = validDays > 0
            ? Calendar.current.date(byAdding: .day, value: validDays, to: Date())
            : nil

        let certCategory = CertificateCategory(rawValue: category.value.lowercased())
            ?? .care

        let instagramHandle = instagram?
            .replacingOccurrences(of: "@", with: "")
            .components(separatedBy: "|").first?
            .trimmingCharacters(in: .whitespaces)

        let tashkentDistrict = TashkentDistrict.from(backendName: district.name)

        return Certificate(
            id: UUID(uuidString: id) ?? UUID(),
            apiId: id,
            title: name,
            description: description ?? "",
            location: partner.name,
            locationDetail: district.name,
            priceMin: price,
            priceMax: price,
            category: certCategory,
            imageURL: imageFullURL,
            imageURLs: allImageURLs,
            instagramHandle: instagramHandle,
            expiresAt: expiresAt,
            district: tashkentDistrict,
            districtName: district.name
        )
    }
}
