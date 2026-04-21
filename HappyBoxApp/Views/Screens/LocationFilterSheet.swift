//
//  LocationFilterSheet.swift
//  HappyBoxApp
//

import SwiftUI

// MARK: - Models

struct LocationSelection: Equatable {
    let cityId: Int
    let districtId: Int?
    let label: String  // display name for the chip
}

private struct RegionData: Decodable, Identifiable {
    let id: Int
    let name: String
    let has_districts: Bool
    let cities: [CityData]
}

private struct CityData: Decodable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Sheet

struct LocationFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: LocationSelection?
    @State private var regions: [RegionData] = []
    @State private var selectedRegion: RegionData?

    var body: some View {
        NavigationStack {
            if let region = selectedRegion {
                CityPickerView(
                    region: region,
                    selection: $selection,
                    onBack: { selectedRegion = nil },
                    onDismiss: { dismiss() }
                )
            } else {
                RegionPickerView(
                    regions: regions,
                    selection: $selection,
                    onSelect: { selectedRegion = $0 },
                    onReset: { selection = nil; dismiss() },
                    onDismiss: { dismiss() }
                )
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { loadRegions() }
    }

    private func loadRegions() {
        guard regions.isEmpty,
              let url = Bundle.main.url(forResource: "regions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([RegionData].self, from: data)
        else { return }
        regions = decoded
    }
}

// MARK: - Level 1: Regions

private struct RegionPickerView: View {
    let regions: [RegionData]
    @Binding var selection: LocationSelection?
    let onSelect: (RegionData) -> Void
    let onReset: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        List {
            Button(action: onReset) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("Все города и районы")
                        .foregroundStyle(.primary)
                    Spacer()
                    if selection == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }

            ForEach(regions) { region in
                Button { onSelect(region) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: region.has_districts ? "building.2.fill" : "map.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(region.name)
                                .foregroundStyle(.primary)
                            if let sel = selection, sel.cityId == region.id {
                                let districtName = region.cities.first { $0.id == sel.districtId }?.name
                                Text(districtName ?? "Весь регион")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        Spacer()

                        if let sel = selection, sel.cityId == region.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Местоположение")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Закрыть") { onDismiss() }
            }
        }
    }
}

// MARK: - Level 2: Cities / Districts

private struct CityPickerView: View {
    let region: RegionData
    @Binding var selection: LocationSelection?
    let onBack: () -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""

    private var filteredCities: [CityData] {
        guard !searchText.isEmpty else { return region.cities }
        return region.cities.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        List {
            // Select entire region (no districtId)
            Button {
                selection = LocationSelection(cityId: region.id, districtId: nil, label: region.name)
                onDismiss()
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)
                    Text("Весь \(region.has_districts ? "город" : "регион")")
                        .foregroundStyle(.primary)
                    Spacer()
                    if selection?.cityId == region.id && selection?.districtId == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }

            // Individual cities/districts
            ForEach(filteredCities) { city in
                let isSelected = selection?.cityId == region.id && selection?.districtId == city.id
                Button {
                    selection = LocationSelection(cityId: region.id, districtId: city.id, label: city.name)
                    onDismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                            .frame(width: 24)
                        Text(city.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Поиск")
        .navigationTitle(region.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { onBack() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Регионы")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Закрыть") { onDismiss() }
            }
        }
    }
}

#Preview {
    LocationFilterSheet(selection: .constant(nil))
}
