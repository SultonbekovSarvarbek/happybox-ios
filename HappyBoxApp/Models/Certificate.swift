//
//  Certificate.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 07/02/26.
//

import Foundation
import SwiftUI

/// Certificate/coupon category — rawValues match backend `category.value`
enum CertificateCategory: String, CaseIterable, Identifiable {
    case care          = "care"
    case health        = "health"
    case food          = "food"
    case education     = "education"
    case fitness       = "fitness"
    case entertainment = "entertainment"
    case travel        = "travel"
    case auto          = "auto"
    case kids          = "kids"
    case home          = "home"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .care:          return "hands.sparkles.fill"
        case .health:        return "heart.text.clipboard.fill"
        case .food:          return "fork.knife"
        case .education:     return "book.fill"
        case .fitness:       return "figure.run"
        case .entertainment: return "theatermasks.fill"
        case .travel:        return "airplane"
        case .auto:          return "car.fill"
        case .kids:          return "teddybear.fill"
        case .home:          return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .care:          return Color(red: 0.85, green: 0.6,  blue: 0.7)   // Rose
        case .health:        return Color(red: 0.7,  green: 0.55, blue: 0.55)  // Coral
        case .food:          return Color(red: 0.65, green: 0.55, blue: 0.5)   // Taupe
        case .education:     return Color(red: 0.5,  green: 0.65, blue: 0.8)   // Sky
        case .fitness:       return Color(red: 0.8,  green: 0.65, blue: 0.5)   // Peach
        case .entertainment: return Color(red: 0.65, green: 0.5,  blue: 0.85)  // Violet
        case .travel:        return Color(red: 0.3,  green: 0.65, blue: 0.8)   // Sky blue
        case .auto:          return Color(red: 0.4,  green: 0.55, blue: 0.7)   // Steel blue
        case .kids:          return Color(red: 0.85, green: 0.7,  blue: 0.3)   // Gold
        case .home:          return Color(red: 0.5,  green: 0.7,  blue: 0.55)  // Sage
        }
    }

    var localizedKey: String {
        "certificates.\(rawValue)"
    }
}

/// Badge type for certificates
enum CertificateBadge: String, Codable {
    case popular = "popular"
    case recommended = "recommended"
    case comingSoon = "coming_soon"
    case planned = "planned"

    var localizedKey: String {
        switch self {
        case .popular: return "certificates.badge.popular"
        case .recommended: return "certificates.badge.recommended"
        case .comingSoon: return "certificates.badge.coming_soon"
        case .planned: return "certificates.badge.planned"
        }
    }

    var icon: String {
        switch self {
        case .popular: return "star.fill"
        case .recommended: return "flame.fill"
        case .comingSoon: return "clock.fill"
        case .planned: return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .popular: return Color(red: 0.95, green: 0.7, blue: 0.2)   // Vibrant gold
        case .recommended: return Color(red: 0.95, green: 0.45, blue: 0.35) // Vibrant coral
        case .comingSoon: return Color(red: 0.5, green: 0.5, blue: 0.55)  // Medium gray
        case .planned: return Color(red: 0.4, green: 0.55, blue: 0.75)   // Medium blue
        }
    }

    var isDisabled: Bool {
        self == .comingSoon || self == .planned
    }
}

/// Tashkent district for certificate location filtering
enum TashkentDistrict: String, CaseIterable, Identifiable {
    case bektemir = "bektemir"
    case chilonzor = "chilonzor"
    case yashnobod = "yashnobod"
    case mirobod = "mirobod"
    case mirzoUlugbek = "mirzo_ulugbek"
    case sergeli = "sergeli"
    case shayxontohur = "shayxontohur"
    case olmazor = "olmazor"
    case uchtepa = "uchtepa"
    case yakkasaroy = "yakkasaroy"
    case yunusobod = "yunusobod"
    case yangihayot = "yangihayot"

    var id: String { rawValue }

    var localizedKey: String {
        "district.\(rawValue)"
    }

    /// Best-effort match from a backend district name string
    static func from(backendName: String) -> TashkentDistrict {
        let lower = backendName.lowercased()
        return allCases.first { lower.contains($0.rawValue.replacingOccurrences(of: "_", with: " ")) }
            ?? .mirobod
    }
}

/// Certificate/coupon model
struct Certificate: Identifiable {
    let id: UUID
    let apiId: String?  // Original backend string ID (used for purchase requests)
    let title: String
    let duration: String?
    let description: String
    let location: String
    let locationDetail: String // Hidden until form submission
    let priceMin: Int
    let priceMax: Int
    let rating: Double?
    let badge: CertificateBadge?
    let category: CertificateCategory
    let imageURL: String?
    let imageURLs: [String]
    let instagramHandle: String?
    let expiresAt: Date?
    let district: TashkentDistrict
    let districtName: String

    /// The ID to send to the backend — prefers raw apiId string, falls back to UUID string
    var backendId: String { apiId ?? id.uuidString }

    var isDisabled: Bool {
        badge?.isDisabled ?? false
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var daysUntilExpiration: Int? {
        guard let expiresAt else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
    }

    var formattedExpirationDate: String? {
        guard let expiresAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: expiresAt)
    }

    var formattedPriceRange: String {
        if priceMin == priceMax || priceMin == 0 {
            return "\(priceMax.formatted()) сум"
        }
        return "\(priceMin.formatted()) – \(priceMax.formatted()) сум"
    }

    var fullTitle: String {
        if let duration = duration {
            return "\(title) — \(duration)"
        }
        return title
    }

    init(
        id: UUID = UUID(),
        apiId: String? = nil,
        title: String,
        duration: String? = nil,
        description: String,
        location: String,
        locationDetail: String = "",
        priceMin: Int,
        priceMax: Int,
        rating: Double? = nil,
        badge: CertificateBadge? = nil,
        category: CertificateCategory,
        imageURL: String? = nil,
        imageURLs: [String] = [],
        instagramHandle: String? = nil,
        expiresAt: Date? = nil,
        district: TashkentDistrict = .mirobod,
        districtName: String = ""
    ) {
        self.id = id
        self.apiId = apiId
        self.title = title
        self.duration = duration
        self.description = description
        self.location = location
        self.locationDetail = locationDetail
        self.priceMin = priceMin
        self.priceMax = priceMax
        self.rating = rating
        self.badge = badge
        self.category = category
        self.imageURL = imageURL
        self.imageURLs = imageURLs.isEmpty && imageURL != nil ? [imageURL!] : imageURLs
        self.instagramHandle = instagramHandle
        self.expiresAt = expiresAt
        self.district = district
        self.districtName = districtName.isEmpty ? district.rawValue : districtName
    }
}

/// Static certificate data
struct CertificateData {
    /// Helper to create a date offset from today by the given number of months
    private static func dateFromNow(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
    }

    static let allCertificates: [Certificate] = [
        // MARK: - Spa & Massage
        Certificate(
            title: "Классический массаж",
            duration: "60 мин",
            description: "Снятие мышечного напряжения и улучшение самочувствия",
            location: "SPA-салон",
            locationDetail: "ул. Амира Темура, 45",
            priceMin: 350_000,
            priceMax: 420_000,
            rating: 4.8,
            badge: .popular,
            category: .care,
            imageURL: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=600&h=400&fit=crop",
            instagramHandle: "classic_spa_uz",
            expiresAt: dateFromNow(months: 6),
            district: .mirobod
        ),
        Certificate(
            title: "SPA-программа «Антистресс»",
            duration: "90 мин",
            description: "Массаж и уход за телом для восстановления энергии",
            location: "SPA-центр",
            locationDetail: "ул. Навои, 12",
            priceMin: 650_000,
            priceMax: 850_000,
            badge: .recommended,
            category: .care,
            instagramHandle: "antistress_spa_uz",
            expiresAt: dateFromNow(months: 4),
            district: .mirzoUlugbek
        ),

        // MARK: - Beauty
        Certificate(
            title: "Маникюр + покрытие",
            description: "Профессиональный уход за ногтями и долговременное покрытие",
            location: "Студия ногтевого сервиса",
            locationDetail: "ТЦ Samarqand Darvoza, 2 этаж",
            priceMin: 200_000,
            priceMax: 280_000,
            category: .care,
            instagramHandle: "nail_studio_uz",
            expiresAt: dateFromNow(months: 3),
            district: .mirobod
        ),
        Certificate(
            title: "Уход за лицом + консультация",
            description: "Очищение и базовый уход с профессиональной рекомендацией",
            location: "Косметологическая клиника",
            locationDetail: "ул. Шота Руставели, 78",
            priceMin: 380_000,
            priceMax: 520_000,
            rating: 4.7,
            category: .care,
            instagramHandle: "beauty_clinic_uz",
            expiresAt: dateFromNow(months: 5),
            district: .mirzoUlugbek
        ),
        Certificate(
            title: "Стрижка и базовый уход",
            description: "Профессиональное обновление образа",
            location: "Салон красоты",
            locationDetail: "ул. Мирабад, 33",
            priceMin: 280_000,
            priceMax: 380_000,
            rating: 4.9,
            category: .care,
            instagramHandle: "beauty_salon_uz",
            expiresAt: dateFromNow(months: 4),
            district: .mirobod
        ),

        // MARK: - Здоровье & Чекапы
        Certificate(
            title: "Профессиональная чистка зубов",
            description: "Удаление налёта и чистка",
            location: "Стоматологическая клиника",
            locationDetail: "ул. Буюк Ипак Йули, 100",
            priceMin: 420_000,
            priceMax: 500_000,
            badge: .comingSoon,
            category: .health,
            district: .yunusobod
        ),
        Certificate(
            title: "Базовый медицинский чекап",
            description: "Консультация и анализы для контроля состояния здоровья",
            location: "Медицинский центр",
            locationDetail: "ул. Амира Темура, 108",
            priceMin: 850_000,
            priceMax: 1_200_000,
            badge: .planned,
            category: .health,
            district: .mirobod
        ),

        // MARK: - Фитнес & Актив
        Certificate(
            title: "Персональная тренировка",
            duration: "60 мин",
            description: "Индивидуальная программа с профессиональным инструктором",
            location: "Фитнес-клуб",
            locationDetail: "ТЦ Mega Planet, 3 этаж",
            priceMin: 250_000,
            priceMax: 350_000,
            rating: 4.6,
            category: .fitness,
            instagramHandle: "fit_trainer_uz",
            expiresAt: dateFromNow(months: 3),
            district: .sergeli
        ),
        Certificate(
            title: "Месячный абонемент",
            description: "Безлимитное посещение тренажёрного зала и групповых занятий",
            location: "Фитнес-центр",
            locationDetail: "ул. Мустакиллик, 55",
            priceMin: 800_000,
            priceMax: 1_200_000,
            badge: .popular,
            category: .fitness,
            instagramHandle: "fit_center_uz",
            expiresAt: dateFromNow(months: 1),
            district: .shayxontohur
        ),

        // MARK: - Рестораны
        Certificate(
            title: "Ужин на двоих",
            description: "Романтический ужин в ресторане с авторской кухней",
            location: "Ресторан",
            locationDetail: "ул. Истикбол, 20",
            priceMin: 500_000,
            priceMax: 800_000,
            badge: .recommended,
            category: .food,
            instagramHandle: "resto_uz",
            expiresAt: dateFromNow(months: 6),
            district: .mirobod
        ),
        Certificate(
            title: "Мастер-класс по кулинарии",
            duration: "3 часа",
            description: "Научитесь готовить изысканные блюда с шеф-поваром",
            location: "Кулинарная студия",
            locationDetail: "ТЦ Samarqand Darvoza",
            priceMin: 350_000,
            priceMax: 500_000,
            rating: 4.8,
            category: .food,
            instagramHandle: "culinary_studio_uz",
            expiresAt: dateFromNow(months: 5),
            district: .mirobod
        ),

        // MARK: - Обучение & Курсы
        Certificate(
            title: "Пробный урок английского",
            duration: "45 мин",
            description: "Бесплатная консультация и тестирование уровня",
            location: "Языковая школа",
            locationDetail: "ул. Навои, 88",
            priceMin: 0,
            priceMax: 150_000,
            category: .education,
            instagramHandle: "lang_school_uz",
            expiresAt: dateFromNow(months: 2),
            district: .mirzoUlugbek
        ),
        Certificate(
            title: "Курс программирования",
            duration: "1 месяц",
            description: "Основы веб-разработки для начинающих",
            location: "IT-школа",
            locationDetail: "IT Park Tashkent",
            priceMin: 1_500_000,
            priceMax: 2_500_000,
            badge: .popular,
            category: .education,
            instagramHandle: "it_school_uz",
            expiresAt: dateFromNow(months: 6),
            district: .mirzoUlugbek
        ),

        // MARK: - Развлечения
        Certificate(
            title: "Квест-комната",
            duration: "60 мин",
            description: "Захватывающий квест для команды до 5 человек",
            location: "Квест-центр",
            locationDetail: "ул. Фаргона йули, 22",
            priceMin: 150_000,
            priceMax: 300_000,
            badge: .popular,
            category: .entertainment,
            instagramHandle: "quest_center_uz",
            expiresAt: dateFromNow(months: 3),
            district: .yashnobod
        ),
        Certificate(
            title: "День рождения в парке",
            duration: "3 часа",
            description: "Аниматоры, игры и праздничный торт",
            location: "Развлекательный парк",
            locationDetail: "Парк Ашхабад",
            priceMin: 1_000_000,
            priceMax: 2_000_000,
            badge: .recommended,
            category: .entertainment,
            instagramHandle: "funpark_uz",
            expiresAt: dateFromNow(months: 6),
            district: .yunusobod
        ),

        // MARK: - Подарки
        Certificate(
            title: "Подарочный набор «Всё включено»",
            description: "Готовый подарочный бокс с сюрпризом на любой случай",
            location: "Подарочный бутик",
            locationDetail: "ТЦ Samarqand Darvoza",
            priceMin: 300_000,
            priceMax: 700_000,
            badge: .recommended,
            category: .home,
            instagramHandle: "happybox_uz",
            expiresAt: dateFromNow(months: 6),
            district: .mirobod
        )
    ]

    static func certificates(for category: CertificateCategory) -> [Certificate] {
        allCertificates.filter { $0.category == category }
    }

    static func certificates(for district: TashkentDistrict) -> [Certificate] {
        allCertificates.filter { $0.district == district }
    }

    static func certificates(category: CertificateCategory?, district: TashkentDistrict?) -> [Certificate] {
        allCertificates.filter { cert in
            (category == nil || cert.category == category) &&
            (district == nil || cert.district == district)
        }
    }
}
