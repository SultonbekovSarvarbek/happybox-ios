//
//  GiftPrimaryButton.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Reusable primary button component with consistent styling
struct GiftPrimaryButton: View {
    // MARK: - Properties

    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    // MARK: - Initializers

    /// Create a primary button with optional icon
    /// - Parameters:
    ///   - title: Button text
    ///   - icon: Optional SF Symbol name
    ///   - isDisabled: Whether button is disabled
    ///   - action: Action to perform on tap
    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))

                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDisabled ? Color.gray.opacity(0.3) : Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(14)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GiftPrimaryButton("Create a Box", icon: "gift.fill") { }

        GiftPrimaryButton("Continue") { }

        GiftPrimaryButton("Send Order", isDisabled: true) { }
    }
    .padding()
}
