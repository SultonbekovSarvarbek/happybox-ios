//
//  AppUpdateService.swift
//  HappyBoxApp
//

import Foundation

struct AppUpdateInfo {
    let version: String
    let storeURL: URL
}

actor AppUpdateService {
    static let shared = AppUpdateService()

    private let bundleID = "uz.happybox.HappyBoxApp"

    /// Returns update info if App Store has a newer version, otherwise nil
    func checkForUpdate() async -> AppUpdateInfo? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)&country=uz") else {
            return nil
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let result = results.first,
              let storeVersion = result["version"] as? String,
              let storeURLString = result["trackViewUrl"] as? String,
              let storeURL = URL(string: storeURLString) else {
            return nil
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        if storeVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
            return AppUpdateInfo(version: storeVersion, storeURL: storeURL)
        }
        return nil
    }
}
