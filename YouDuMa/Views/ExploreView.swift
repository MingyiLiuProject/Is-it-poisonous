import SwiftUI

struct ExploreView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var query = ""
    @State private var selectedPet: PetType?
    @FocusState private var isSearchFocused: Bool

    private var results: [Plant] {
        PlantRepository.search(query, pet: selectedPet)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.cream, AppTheme.moss.opacity(0.055)],
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
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
                                .contentTransition(reduceMotion ? .opacity : .numericText())
                                .animation(
                                    AppMotion.responsive(reduceMotion: reduceMotion),
                                    value: results.count
                                )
                        }
                        .padding(.top, 8)

                        if results.isEmpty {
                            ContentUnavailableView(
                                "没有找到植物",
                                systemImage: "leaf",
                                description: Text("可尝试中文、英文、学名、拼音或更短的关键词")
                            )
                            .frame(minHeight: 260)
                        } else {
                            ForEach(results) { plant in
                                NavigationLink(value: plant) {
                                    PlantRow(plant: plant)
                                }
                                .buttonStyle(PressableCardButtonStyle())
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
            .sensoryFeedback(
                .selection,
                trigger: selectedPet?.rawValue ?? "all"
            )
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Text("🪴")
                .font(.system(size: 48))
                .accessibilityHidden(true)
            Text("有毒吗？")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .tracking(-0.6)
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
            TextField("搜索中文、英文、学名或拼音", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFocused)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .accessibilityLabel("清除搜索")
                .buttonStyle(PressableControlButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(AppTheme.paper)
            } else {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(.regularMaterial)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    isSearchFocused ? AppTheme.moss.opacity(0.75) : AppTheme.hairline,
                    lineWidth: isSearchFocused ? 1.5 : 1
                )
        }
        .shadow(color: Color.black.opacity(isSearchFocused ? 0.10 : 0.055), radius: 18, y: 8)
        .animation(
            AppMotion.responsive(reduceMotion: reduceMotion),
            value: isSearchFocused
        )
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(AppMotion.responsive(reduceMotion: reduceMotion)) {
                action()
            }
        } label: {
            HStack(spacing: 6) {
                Text(emoji)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .foregroundStyle(isSelected ? Color.white : AppTheme.forest)
            .background(isSelected ? AppTheme.forestFill : AppTheme.paper, in: Capsule())
            .overlay {
                Capsule().stroke(isSelected ? Color.white.opacity(0.12) : AppTheme.hairline)
            }
            .shadow(color: Color.black.opacity(isSelected ? 0.09 : 0.025), radius: 8, y: 4)
        }
        .buttonStyle(PressableControlButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
