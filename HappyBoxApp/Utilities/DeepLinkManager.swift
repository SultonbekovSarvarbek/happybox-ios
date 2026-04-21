//
//  DeepLinkManager.swift
//  HappyBoxApp
//

import Foundation
import Observation

/// Handles deep links of the form: happybox://cards/{instagram_handle}
@Observable
class DeepLinkManager {
    static let shared = DeepLinkManager()

    /// Instagram handle extracted from the deep link (without @)
    var pendingCardHandle: String? = nil

    private init() {}

    /// Parse incoming URL and store the handle if valid
    func handle(url: URL) {
        guard url.scheme == "happybox",
              url.host == "cards",
              let handle = url.pathComponents.dropFirst().first,
              !handle.isEmpty
        else { return }

        pendingCardHandle = handle.lowercased()
    }
}
