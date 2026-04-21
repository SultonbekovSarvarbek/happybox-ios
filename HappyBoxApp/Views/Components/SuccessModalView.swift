//
//  SuccessModalView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 11/02/26.
//

import SwiftUI

// MARK: - SuccessModalView

struct SuccessModalView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onDismiss: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .scaleEffect(showCheckmark ? 1 : 0.3)
                    .opacity(showCheckmark ? 1 : 0)

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                GiftPrimaryButton(buttonTitle) {
                    onDismiss()
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - Clear Background Helper

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview

#Preview {
    SuccessModalView(
        title: "Заявка отправлена!",
        message: "Мы свяжемся с вами в ближайшее время для подтверждения заказа",
        buttonTitle: "Отлично!"
    ) { }
}
