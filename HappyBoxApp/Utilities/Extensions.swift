//
//  Extensions.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI
import UIKit

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(Constants.CornerRadius.medium)
            .shadow(
                color: .black.opacity(Constants.Shadow.opacity),
                radius: Constants.Shadow.radius,
                x: 0,
                y: 2
            )
    }
}

extension Notification.Name {
    static let navigateToPurchaseRequests = Notification.Name("navigateToPurchaseRequests")
    static let openPurchaseRequestsInProfile = Notification.Name("openPurchaseRequestsInProfile")
}

extension Color {
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondarySystemBackground
                : UIColor.systemGray5
        })
    }

    static var cardShadow: Color {
        Color.black.opacity(Constants.Shadow.opacity)
    }
}
