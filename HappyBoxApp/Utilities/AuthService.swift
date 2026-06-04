//
//  AuthService.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse(statusCode: Int, message: String?)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL."
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .invalidResponse(let statusCode, let message):
            // Prefer the server's specific reason (expired code, invalid code,
            // too many attempts, etc.). Fall back to the generic credentials
            // message only when the server didn't say why.
            if let msg = message, !msg.isEmpty {
                return Self.localizedServerMessage(msg, statusCode: statusCode)
            }
            if statusCode == 401 {
                return "Неверный номер телефона или пароль"
            }
            return "Ошибка сервера. Попробуйте позже."
        case .decodingError:
            return "Ошибка обработки ответа сервера."
        }
    }

    private static func localizedServerMessage(_ message: String, statusCode: Int) -> String {
        let lower = message.lowercased()
        // OTP (passwordless) login — check before the generic "not found" rule,
        // since the expired-code message also contains "not found".
        if lower.contains("expired") {
            return "Код истёк. Запросите новый код."
        }
        if lower.contains("too many attempts") {
            return "Слишком много попыток. Запросите новый код."
        }
        if lower.contains("invalid code") {
            return "Неверный код. Проверьте и попробуйте ещё раз."
        }
        if lower.contains("invalid credentials") || lower.contains("wrong password") {
            return "Неверный номер телефона или пароль"
        }
        if lower.contains("user not found") || lower.contains("not found") {
            return "Пользователь не найден"
        }
        if lower.contains("already exists")
            || lower.contains("already registered")
            || lower.contains("already in use")
            || (lower.contains("phone") && lower.contains("in use"))
            || (lower.contains("phone") && lower.contains("taken")) {
            return "Этот номер телефона или имя пользователя уже зарегистрированы"
        }
        if lower.contains("username") && (lower.contains("taken") || lower.contains("exists") || lower.contains("in use")) {
            return "Это имя пользователя уже занято"
        }
        if statusCode >= 500 {
            return "Ошибка сервера. Попробуйте позже."
        }
        // Fall back to the raw server message if it's already in Russian or short enough.
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed.count < 200 {
            return trimmed
        }
        return "Ошибка. Попробуйте ещё раз."
    }
}

@MainActor
final class AuthService {
    static let shared = AuthService()

    private let baseURL: String

    private let snakeCaseDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private init() {
        let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? ""
        self.baseURL = url
        if url.isEmpty { }
    }

    func login(phone: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(phone: phone, password: password)
        return try await request(path: "/auth/mobile/login", body: body)
    }

    func register(
        username: String,
        firstName: String,
        lastName: String,
        phone: String,
        password: String,
        telegramUsername: String?,
        birthDate: String
    ) async throws -> AuthResponse {
        let body = RegisterRequest(
            username: username,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            password: password,
            telegramUsername: telegramUsername,
            birthDate: birthDate
        )
        return try await request(path: "/auth/mobile/register", body: body)
    }

    /// Step 1 of passwordless login: ask the backend to send a login code to
    /// the user's Telegram via the bot.
    func requestOtp(phone: String) async throws -> OtpRequestResponse {
        let fullURL = baseURL + "/auth/mobile/otp/request"
        guard let url = URL(string: fullURL) else { throw AuthError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        req.httpBody = try? JSONEncoder().encode(OtpRequestBody(phone: phone))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw AuthError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse(statusCode: 0, message: nil)
        }
        let rawBody = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(http.statusCode) else {
            throw AuthError.invalidResponse(statusCode: http.statusCode, message: rawBody.isEmpty ? nil : rawBody)
        }
        do {
            return try snakeCaseDecoder.decode(OtpRequestResponse.self, from: data)
        } catch {
            throw AuthError.decodingError(error)
        }
    }

    /// Step 2 of passwordless login: verify the code and receive an access token.
    func verifyOtp(phone: String, code: String) async throws -> AuthResponse {
        let body = OtpVerifyRequest(phone: phone, code: code)
        return try await request(path: "/auth/mobile/otp/verify", body: body)
    }

    func checkUsername(_ username: String) async throws -> Bool {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        let fullURL = baseURL + "/auth/check-username/\(encoded)"
        guard let url = URL(string: fullURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return false
        }

        struct CheckResponse: Decodable { let available: Bool }
        return (try? JSONDecoder().decode(CheckResponse.self, from: data))?.available ?? false
    }

    func logout(token: String) async throws {
        let fullURL = baseURL + "/auth/mobile/logout"
        guard let url = URL(string: fullURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { return }
        _ = http.statusCode
    }

    func fetchProfile(token: String) async throws -> UserProfile {
        let fullURL = baseURL + "/mobile/profile"
        guard let url = URL(string: fullURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse(statusCode: 0, message: nil)
        }

        let rawBody = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .authTokenExpired, object: nil)
                }
            }
            throw AuthError.invalidResponse(statusCode: http.statusCode, message: rawBody.isEmpty ? nil : rawBody)
        }

        do {
            return try snakeCaseDecoder.decode(UserProfile.self, from: data)
        } catch {
            throw AuthError.decodingError(error)
        }
    }

    // MARK: - Private

    private func request<T: Encodable>(path: String, body: T) async throws -> AuthResponse {
        let fullURL = baseURL + path
        guard let url = URL(string: fullURL) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try? JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse(statusCode: 0, message: nil)
        }

        let rawBody = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(http.statusCode) else {
            // Try JSON message first, fall back to raw body text
            let jsonMessage = try? snakeCaseDecoder.decode(AuthResponse.self, from: data)
            let message = jsonMessage?.message ?? (rawBody.isEmpty ? nil : rawBody)
            throw AuthError.invalidResponse(statusCode: http.statusCode, message: message)
        }

        if data.isEmpty {
            return AuthResponse(accessToken: nil, token: nil, message: nil)
        }

        return (try? snakeCaseDecoder.decode(AuthResponse.self, from: data))
            ?? AuthResponse(accessToken: nil, token: nil, message: nil)
    }
}
