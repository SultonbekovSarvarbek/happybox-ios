//
//  Constants.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct Constants {
    // Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    // Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
    }

    // Shadow
    struct Shadow {
        static let radius: CGFloat = 5
        static let opacity: Double = 0.05
    }

    // Pricing (values in thousands, e.g. 5.999 = 5 999 сум)
    struct Pricing {
        static let serviceFee: Double = 5.999
        static let deliveryFee: Double = 25.0

        static var serviceFeeSUM: Int { Int(serviceFee * 1000) }
        static var deliveryFeeSUM: Int { Int(deliveryFee * 1000) }

        static var formattedServiceFee: String { "\(serviceFeeSUM.formatted()) сум" }
        static var formattedDeliveryFee: String { "\(deliveryFeeSUM.formatted()) сум" }
    }

    // Image
    struct Image {
        static let cardResolution = "600x600"
        static let thumbnailResolution = "300x300"

        static func processURL(_ url: String, resolution: String = cardResolution) -> String {
            url.replacingOccurrences(of: "{w}x{h}", with: resolution)
               .replacingOccurrences(of: "{w}", with: resolution.components(separatedBy: "x").first ?? "600")
               .replacingOccurrences(of: "{h}", with: resolution.components(separatedBy: "x").last ?? "600")
        }
    }
}
