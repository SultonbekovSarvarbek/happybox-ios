//
//  FAQView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 07/02/26.
//

import SwiftUI

/// FAQ item model
struct FAQItem: Identifiable {
    let id = UUID()
    let questionKey: String
    let answerKey: String
    let icon: String
}

/// FAQ screen explaining certificates, coupons, and how the app works
struct FAQView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localization
    @State private var expandedItem: UUID?

    private let faqItems: [FAQItem] = [
        FAQItem(
            questionKey: "faq.what_is_certificate.question",
            answerKey: "faq.what_is_certificate.answer",
            icon: "ticket.fill"
        ),
        FAQItem(
            questionKey: "faq.how_it_works.question",
            answerKey: "faq.how_it_works.answer",
            icon: "gearshape.fill"
        ),
        FAQItem(
            questionKey: "faq.how_to_use.question",
            answerKey: "faq.how_to_use.answer",
            icon: "hand.tap.fill"
        ),
        FAQItem(
            questionKey: "faq.validity.question",
            answerKey: "faq.validity.answer",
            icon: "calendar"
        ),
        FAQItem(
            questionKey: "faq.refund.question",
            answerKey: "faq.refund.answer",
            icon: "arrow.uturn.backward.circle.fill"
        ),
        FAQItem(
            questionKey: "faq.gift_box.question",
            answerKey: "faq.gift_box.answer",
            icon: "gift.fill"
        )
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header illustration
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text(localization.localized("faq.title"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(localization.localized("faq.subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // FAQ items
                    VStack(spacing: 12) {
                        ForEach(faqItems) { item in
                            FAQItemView(
                                item: item,
                                isExpanded: expandedItem == item.id,
                                localization: localization
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    if expandedItem == item.id {
                                        expandedItem = nil
                                    } else {
                                        expandedItem = item.id
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Add certificate invitation
                    VStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.accentColor)

                        Text(localization.localized("faq.add_certificate.title"))
                            .font(.system(size: 17, weight: .semibold))
                            .multilineTextAlignment(.center)

                        Text(localization.localized("faq.add_certificate.description"))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                            Text(localization.localized("faq.add_certificate.telegram"))
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Color.accentColor)

                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                            Text(localization.localized("faq.add_certificate.phone"))
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Contact support
                    VStack(spacing: 12) {
                        Text(localization.localized("faq.more_questions"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            ContactSupportView()
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text(localization.localized("settings.contact_support"))
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("product_detail.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FAQ Item View

struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let localization: LocalizationManager
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)

                    Text(localization.localized(item.questionKey))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Answer (expandable)
            if isExpanded {
                Text(localization.localized(item.answerKey))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .padding(.leading, 36)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    FAQView()
}
