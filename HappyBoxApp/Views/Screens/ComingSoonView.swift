//
//  ComingSoonView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 09/01/26.
//

import SwiftUI

/// Coming soon screen for ready-made gift selection feature
struct ComingSoonView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localization

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Coming Soon Text
                Text(localization.localized("coming_soon"))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ComingSoonView()
    }
}
