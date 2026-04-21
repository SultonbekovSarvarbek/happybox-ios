//
//  AuthModels.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation

struct LoginRequest: Encodable, Sendable {
    let phone: String
    let password: String
}

struct RegisterRequest: Encodable, Sendable {
    let username: String
    let firstName: String
    let lastName: String
    let phone: String
    let password: String
    let telegramUsername: String?
    let birthDate: String

    enum CodingKeys: String, CodingKey {
        case username, firstName, lastName, phone, password, telegramUsername, birthDate
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(username, forKey: .username)
        try c.encode(firstName, forKey: .firstName)
        try c.encode(lastName, forKey: .lastName)
        try c.encode(phone, forKey: .phone)
        try c.encode(password, forKey: .password)
        try c.encodeIfPresent(telegramUsername, forKey: .telegramUsername)
        try c.encode(birthDate, forKey: .birthDate)
    }
}

struct AuthResponse: Decodable, Sendable {
    let accessToken: String?  // server sends "access_token" → decoded via convertFromSnakeCase
    let token: String?
    let message: String?

    var resolvedToken: String? {
        accessToken ?? token
    }
}

struct UserProfile: Codable, Sendable {
    var id: String?
    var username: String
    var firstName: String
    var lastName: String
    var phone: String
    var telegramUsername: String?
    var birthDate: String
    var role: String?

    var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? username : name
    }
}
