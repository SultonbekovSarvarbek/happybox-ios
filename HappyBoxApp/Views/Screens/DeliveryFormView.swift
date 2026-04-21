//
//  DeliveryFormView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

/// Delivery and recipient information form screen
struct DeliveryFormView: View {
    // MARK: - Properties

    @Environment(CartViewModel.self) private var cart
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    // Form fields enum for focus management
    enum Field {
        case name, phone, message
    }

    // Delivery time options (24 hours)
    private static let timeOptions = [
        "00:00", "01:00", "02:00", "03:00", "04:00", "05:00",
        "06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
        "12:00", "13:00", "14:00", "15:00", "16:00", "17:00",
        "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"
    ]

    // Computed delivery dates (today, tomorrow, day after tomorrow)
    private var deliveryDates: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: localization.currentLanguage == "uz" ? "uz_UZ" : "ru_RU")
        dateFormatter.dateFormat = "d MMMM"

        let today = Date()
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: today)!

        return [
            localization.localized("delivery.date_today"),
            localization.localized("delivery.date_tomorrow"),
            dateFormatter.string(from: dayAfterTomorrow)
        ]
    }

    // MARK: - Body

    var body: some View {
        @Bindable var cart = cart

        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localized("delivery.title"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(localization.localized("delivery.description"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tashkent only notice
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)

                    Text(localization.localized("delivery.tashkent_only"))
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // Form fields
                VStack(spacing: 16) {
                    // Recipient Name (Required)
                    FormField(
                        title: localization.localized("delivery.recipient_name"),
                        placeholder: localization.localized("delivery.recipient_name_placeholder"),
                        text: $cart.deliveryInfo.recipientName,
                        icon: "person.fill",
                        isRequired: true
                    )
                    .focused($focusedField, equals: .name)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .phone
                    }

                    // Phone Number (Required)
                    FormField(
                        title: localization.localized("delivery.phone"),
                        placeholder: localization.localized("delivery.phone_placeholder"),
                        text: $cart.deliveryInfo.phoneNumber,
                        icon: "phone.fill",
                        isRequired: true
                    )
                    .focused($focusedField, equals: .phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .message
                    }

                    // Delivery Date Picker (Required)
                    VStack(alignment: .leading, spacing: 8) {
                        // Field label
                        HStack(spacing: 4) {
                            Text(localization.localized("delivery.date"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text("*")
                                .foregroundStyle(.red)
                        }

                        // Date selector
                        Menu {
                            ForEach(deliveryDates, id: \.self) { date in
                                Button {
                                    cart.deliveryInfo.deliveryDate = date
                                } label: {
                                    HStack {
                                        Text(date)
                                        if cart.deliveryInfo.deliveryDate == date {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text(cart.deliveryInfo.deliveryDate.isEmpty ? localization.localized("delivery.date_placeholder") : cart.deliveryInfo.deliveryDate)
                                    .foregroundStyle(cart.deliveryInfo.deliveryDate.isEmpty ? .secondary : .primary)

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }

                    // Delivery Time Picker (Required)
                    VStack(alignment: .leading, spacing: 8) {
                        // Field label
                        HStack(spacing: 4) {
                            Text(localization.localized("delivery.time"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text("*")
                                .foregroundStyle(.red)
                        }

                        // Time selector
                        Menu {
                            ForEach(Self.timeOptions, id: \.self) { time in
                                Button {
                                    cart.deliveryInfo.deliveryTime = time
                                } label: {
                                    HStack {
                                        Text(time)
                                        if cart.deliveryInfo.deliveryTime == time {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text(cart.deliveryInfo.deliveryTime.isEmpty ? localization.localized("delivery.time_placeholder") : cart.deliveryInfo.deliveryTime)
                                    .foregroundStyle(cart.deliveryInfo.deliveryTime.isEmpty ? .secondary : .primary)

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }

                    // Optional Message
                    FormField(
                        title: localization.localized("delivery.message"),
                        placeholder: localization.localized("delivery.message_placeholder"),
                        text: $cart.deliveryInfo.message,
                        icon: "text.bubble.fill",
                        isRequired: false,
                        axis: .vertical
                    )
                    .focused($focusedField, equals: .message)
                    .submitLabel(.done)
                }

                // Price breakdown
                VStack(spacing: 12) {
                    Divider()

                    // Items subtotal
                    HStack {
                        Text(localization.localized("delivery.items_total"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cart.formattedTotalPrice)
                            .font(.subheadline)
                    }

                    // Service fee
                    HStack {
                        Text(localization.localized("delivery.service_fee"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Constants.Pricing.formattedServiceFee)
                            .font(.subheadline)
                    }

                    // Delivery fee
                    HStack {
                        Text(localization.localized("delivery.delivery_fee"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Constants.Pricing.formattedDeliveryFee)
                            .font(.subheadline)
                    }

                    Divider()

                    // Grand total
                    HStack {
                        Text(localization.localized("delivery.grand_total"))
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text(cart.formattedGrandTotal)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }

                    Divider()
                }

                // Send Order Button
                GiftPrimaryButton(
                    cart.isSendingOrder ? localization.localized("delivery.sending") : localization.localized("delivery.send_order"),
                    icon: cart.isSendingOrder ? "hourglass" : "paperplane.fill",
                    isDisabled: !cart.deliveryInfo.isValid || cart.isSendingOrder
                ) {
                    // Hide keyboard
                    focusedField = nil

                    // Send order via Telegram Bot API
                    Task {
                        await cart.sendOrder()

                        // Show appropriate alert based on result
                        if cart.orderSentSuccessfully {
                            showingSuccessAlert = true
                        } else if cart.orderError != nil {
                            showingErrorAlert = true
                        }
                    }
                }
                .padding(.top, 8)

                // Loading indicator
                if cart.isSendingOrder {
                    HStack {
                        ProgressView()
                            .tint(.accentColor)
                        Text(localization.localized("delivery.sending_order"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }

                // Helper text
                if !cart.deliveryInfo.isValid {
                    VStack(alignment: .leading, spacing: 4) {
                        if !cart.deliveryInfo.phoneNumber.isEmpty && !cart.deliveryInfo.isPhoneValid {
                            Text(localization.localized("delivery.invalid_phone"))
                                .font(.footnote)
                                .foregroundStyle(.red)
                        } else {
                            Text(localization.localized("delivery.fill_required"))
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(localization.localized("delivery.info_section"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(localization.localized("delivery.order_sent"), isPresented: $showingSuccessAlert) {
            Button(localization.localized("delivery.great")) {
                // Clear delivery info form
                cart.deliveryInfo = DeliveryInfo()

                // Clear cart - this will trigger BoxSummaryView to auto-dismiss
                cart.clearCart()

                // Reset order state
                cart.resetOrderState()

                // Dismiss DeliveryFormView to BoxSummaryView
                // BoxSummaryView will auto-dismiss to main screen when it detects empty cart
                dismiss()
            }
        } message: {
            Text(localization.localized("delivery.order_success"))
        }
        .alert(localization.localized("delivery.send_error"), isPresented: $showingErrorAlert) {
            Button(localization.localized("delivery.retry")) {
                cart.resetOrderState()
            }
            Button(localization.localized("delivery.cancel"), role: .cancel) {
                cart.resetOrderState()
            }
        } message: {
            Text(cart.orderErrorMessage)
        }
    }
}

// MARK: - Form Field Component

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isRequired: Bool = true
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field label
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                if isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                }
            }

            // Text field
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                if axis == .vertical {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...5)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeliveryFormView()
            .environment({
                let cart = CartViewModel()
                if let product = ProductDataService.shared.allProducts.first {
                    cart.addProduct(product)
                }
                return cart
            }())
    }
}
