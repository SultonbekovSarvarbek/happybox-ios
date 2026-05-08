//
//  CertificateService.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation

// MARK: - API Error

struct APIError: LocalizedError {
    let statusCode: Int
    let serverMessage: String

    var errorDescription: String? {
        "Ошибка сервера (\(statusCode)): \(serverMessage)"
    }

    /// Parse server JSON body `{ "message": "..." }` or fall back to raw string
    static func from(data: Data, statusCode: Int) -> APIError {
        if statusCode == 401 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .authTokenExpired, object: nil)
            }
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let msg = json["message"] as? String
                ?? json["error"] as? String
                ?? HTTPURLResponse.localizedString(forStatusCode: statusCode)
            return APIError(statusCode: statusCode, serverMessage: msg)
        }
        let raw = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: statusCode)
        return APIError(statusCode: statusCode, serverMessage: raw)
    }
}

// MARK: - Service

@MainActor
final class CertificateService {
    static let shared = CertificateService()

    private let baseURL: String

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private init() {
        baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? ""
    }

    func fetchCards(cityId: Int? = nil, districtId: Int? = nil) async throws -> [MobileCard] {
        var components = URLComponents(string: baseURL + "/mobile/cards")!
        var queryItems: [URLQueryItem] = []
        if let cityId { queryItems.append(URLQueryItem(name: "cityId", value: "\(cityId)")) }
        if let districtId { queryItems.append(URLQueryItem(name: "districtId", value: "\(districtId)")) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        if let paginated = try? decoder.decode(PaginatedResponse<MobileCard>.self, from: data) {
            return paginated.data
        }
        if let wrapped = try? decoder.decode(WrappedArray<MobileCard>.self, from: data) {
            return wrapped.data
        }
        return try decoder.decode([MobileCard].self, from: data)
    }

    func fetchCardDetail(id: String) async throws -> MobileCardDetail {
        guard let url = URL(string: baseURL + "/mobile/cards/\(id)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        return try decoder.decode(MobileCardDetail.self, from: data)
    }

    func fetchPurchaseRequests(token: String?) async throws -> [PurchaseRequest] {
        guard let url = URL(string: baseURL + "/mobile/purchase-requests") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse

        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        // Try direct array first, then common wrapper shapes
        if let items = try? decoder.decode([PurchaseRequest].self, from: data) {
            return items
        }
        // Wrapped: { "data": [...] }
        if let wrapped = try? decoder.decode(WrappedArray<PurchaseRequest>.self, from: data) {
            return wrapped.data
        }
        // Wrapped: { "items": [...] }
        if let wrapped = try? decoder.decode(WrappedItems<PurchaseRequest>.self, from: data) {
            return wrapped.items
        }
        // Fall back to strict decode so the error message is useful
        return try decoder.decode([PurchaseRequest].self, from: data)
    }

    func fetchReceivedVouchers(token: String?) async throws -> [ReceivedVoucher] {
        guard let url = URL(string: baseURL + "/mobile/vouchers/received") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse

        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        if let items = try? decoder.decode([ReceivedVoucher].self, from: data) { return items }
        if let wrapped = try? decoder.decode(WrappedArray<ReceivedVoucher>.self, from: data) { return wrapped.data }
        if let wrapped = try? decoder.decode(WrappedItems<ReceivedVoucher>.self, from: data) { return wrapped.items }
        return try decoder.decode([ReceivedVoucher].self, from: data)
    }

    func fetchReceivedGiftOrders(token: String?) async throws -> [MobileGiftOrder] {
        try await fetchGiftOrders(path: "/mobile/gift-orders/received", token: token)
    }

    func fetchSentGiftOrders(token: String?) async throws -> [MobileGiftOrder] {
        try await fetchGiftOrders(path: "/mobile/gift-orders/sent", token: token)
    }

    private func fetchGiftOrders(path: String, token: String?) async throws -> [MobileGiftOrder] {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }
        if let items = try? decoder.decode([MobileGiftOrder].self, from: data) { return items }
        if let wrapped = try? decoder.decode(WrappedArray<MobileGiftOrder>.self, from: data) { return wrapped.data }
        if let wrapped = try? decoder.decode(WrappedItems<MobileGiftOrder>.self, from: data) { return wrapped.items }
        return try decoder.decode([MobileGiftOrder].self, from: data)
    }

    func searchUser(username: String? = nil, phone: String? = nil, token: String?) async throws -> UserSearchResult {
        var components = URLComponents(string: baseURL + "/mobile/users/search")
        if let username {
            components?.queryItems = [URLQueryItem(name: "username", value: username)]
        } else if let phone {
            components?.queryItems = [URLQueryItem(name: "phone", value: phone)]
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        return try decoder.decode(UserSearchResult.self, from: data)
    }

    func giftVoucher(voucherId: String, toUsername: String? = nil, toPhone: String? = nil, token: String?) async throws {
        guard let url = URL(string: baseURL + "/mobile/vouchers/\(voucherId)/gift") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: String] = [:]
        if let toUsername { body["toUsername"] = toUsername }
        if let toPhone    { body["toPhone"]    = toPhone }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse

        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

    }

    func fetchPartnerServices(cardId: String) async throws -> [PartnerServiceItem] {
        guard let url = URL(string: baseURL + "/mobile/cards/\(cardId)/services") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        if let items = try? decoder.decode([PartnerServiceItem].self, from: data) { return items }
        if let wrapped = try? decoder.decode(WrappedArray<PartnerServiceItem>.self, from: data) { return wrapped.data }
        return try decoder.decode([PartnerServiceItem].self, from: data)
    }

    func createCustomCertificate(partnerCardId: String, serviceItemIds: [String], token: String?) async throws -> CustomCertificateResponse {
        guard let url = URL(string: baseURL + "/mobile/certificates/custom") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "partnerCardId": partnerCardId,
            "serviceItemIds": serviceItemIds
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        return try decoder.decode(CustomCertificateResponse.self, from: data)
    }

    func fetchCustomCertificate(id: String, token: String?) async throws -> CustomCertificateDetail {
        guard let url = URL(string: baseURL + "/mobile/certificates/custom/\(id)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }

        return try decoder.decode(CustomCertificateDetail.self, from: data)
    }

    func submitPurchaseRequest(certificateId: String, token: String?) async throws {
        guard let url = URL(string: baseURL + "/mobile/purchase-requests") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = ["certificateId": certificateId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse

        guard (200...299).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }
    }
}

// MARK: - User search

struct UserSearchResult: Decodable, Sendable {
    let id: String
    let username: String
    let firstName: String?
}

// MARK: - Response wrapper helpers

private struct WrappedArray<T: Decodable>: Decodable {
    let data: [T]
}

private struct WrappedItems<T: Decodable>: Decodable {
    let items: [T]
}
