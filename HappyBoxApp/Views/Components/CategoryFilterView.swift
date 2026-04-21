//
//  CategoryFilterView.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct CategoryCircleChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : color)
                }

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? color : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 64, height: 26, alignment: .top)
            }
            .frame(height: 90)
        }
        .buttonStyle(.plain)
    }
}

struct DistrictPillChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
