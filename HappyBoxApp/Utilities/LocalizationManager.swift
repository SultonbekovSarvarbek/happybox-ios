//
//  LocalizationManager.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 09/01/26.
//

import Foundation
import Observation

/// Manages app localization and provides immediate language switching
@Observable
class LocalizationManager {
    // MARK: - Properties

    /// Shared instance for use in ViewModels that can't use @Environment
    static let shared = LocalizationManager()

    /// Current selected language code (ru, uz)
    var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            loadTranslations()
        }
    }

    /// Dictionary of loaded translations
    private var translations: [String: String] = [:]

    // MARK: - Initialization

    init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "ru"
        loadTranslations()
    }

    // MARK: - Public Methods

    /// Get localized string for a key
    /// - Parameter key: Translation key (e.g., "home.subtitle")
    /// - Returns: Localized string, or key if not found
    func localized(_ key: String) -> String {
        guard let value = translations[key] else {
                return key
        }
        return value
    }

    /// Get pluralized string based on count
    /// - Parameters:
    ///   - baseKey: Base translation key (e.g., "items")
    ///   - count: Number to determine plural form
    /// - Returns: Formatted string with count and proper plural form
    func plural(_ baseKey: String, count: Int) -> String {
        let suffix = getPluralSuffix(for: count, language: currentLanguage)
        let key = "\(baseKey).\(suffix)"
        let word = translations[key] ?? translations["\(baseKey).many"] ?? ""
        return "\(count) \(word)"
    }

    // MARK: - Private Methods

    /// Load translations from JSON file for current language
    private func loadTranslations() {
        // Try without subdirectory first (if files are at root of bundle)
        if let url = Bundle.main.url(forResource: currentLanguage, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            translations = json
            return
        }

        // Try with subdirectory as fallback
        if let url = Bundle.main.url(forResource: currentLanguage, withExtension: "json", subdirectory: "Resources/Localizations"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            translations = json
            return
        }
    }

    /// Determine plural suffix based on count and language
    private func getPluralSuffix(for count: Int, language: String) -> String {
        switch language {
        case "ru":
            return getRussianPluralSuffix(count)
        case "uz":
            return "plural" // Uzbek doesn't have plural forms
        default:
            return "many"
        }
    }

    /// Russian pluralization rules
    private func getRussianPluralSuffix(_ count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100

        if remainder100 >= 11 && remainder100 <= 14 {
            return "many"
        }
        if remainder10 == 1 {
            return "singular"
        }
        if remainder10 >= 2 && remainder10 <= 4 {
            return "few"
        }
        return "many"
    }
}
