//
//  ProductImageCarousel.swift
//  HappyBoxApp
//
//  Created by Sultonbekov Sarvar on 01/01/26.
//

import SwiftUI

struct ProductImageCarousel: View {
    let imageNames: [String]

    var body: some View {
        TabView {
            ForEach(imageNames, id: \.self) { imageName in
                Image(systemName: imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color(.systemGray6))
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 300)
    }
}

#Preview {
    ProductImageCarousel(imageNames: ["tshirt.fill", "photo", "heart.fill"])
}
