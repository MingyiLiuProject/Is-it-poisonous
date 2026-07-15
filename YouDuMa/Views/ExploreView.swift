import SwiftUI

struct ExploreView: View {
    @State private var query = ""
    @State private var selectedPet: PetType?

    private var results: [Plant] {
        PlantRepository.search(query, pet: selectedPet)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 14) {
                        hero
                        searchField
                        petFilters

                        HStack {
                            Text(resultTitle)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(results.count) 种")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        if results.isEmpty {
                            ContentUnavailableView(
                                "没有找到植物",
                                systemImage: "leaf",
                                description: Text("试试英文名、学名或更短的关键词")
                            )
                            .frame(minHeight: 260)
                        } else {
                            ForEach(results) { plant in
                                NavigationLink(value: plant) {
                                    PlantRow(plant: plant)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Text("🪴")
                .font(.system(size: 52))
                .accessibilityHidden(true)
            Text("有毒吗？")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.forest)
            Text("快速查看常见植物对宠物的潜在风险")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 26)
        .padding(.bottom, 8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.moss)
            TextField("搜索中文名、英文名或学名", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .accessibilityLabel("清除搜索")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: AppTheme.forest.opacity(0.09), radius: 18, y: 8)
    }

    private var petFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                FilterChip(title: "全部", emoji: "✨", isSelected: selectedPet == nil) {
                    selectedPet = nil
                }

                ForEach(PetType.allCases) { pet in
                    FilterChip(title: pet.title, emoji: pet.emoji, isSelected: selectedPet == pet) {
                        selectedPet = pet
                    }
                }
            }
        }
        .contentMargins(.vertical, 4)
    }

    private var resultTitle: String {
        if let selectedPet {
            return "对\(selectedPet.title)有毒"
        }
        return query.isEmpty ? "常见植物" : "搜索结果"
    }
}
private struct FilterChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .foregroundStyle(isSelected ? Color.white : AppTheme.forest)
            .background(isSelected ? AppTheme.forest : AppTheme.paper, in: Capsule())
            .overlay {
                if !isSelected {
                    Capsule().stroke(AppTheme.forest.opacity(0.12))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
