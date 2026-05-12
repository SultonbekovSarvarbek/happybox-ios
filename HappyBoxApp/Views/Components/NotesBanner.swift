//
//  NotesBanner.swift
//  HappyBoxApp
//

import SwiftUI

struct NotesBanner: View {
    let notes: [String]

    init?(notes: [String]?) {
        let cleaned = (notes ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return nil }
        self.notes = cleaned
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(red: 0.72, green: 0.52, blue: 0.04))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 0.42, green: 0.33, blue: 0.07))
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 0.42, green: 0.33, blue: 0.07))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.965, blue: 0.878))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
