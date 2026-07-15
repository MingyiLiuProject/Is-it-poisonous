import SwiftUI

struct PlantDetailView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    let plant: Plant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                toxicityOverview
                informationCard(
                    title: "毒性成分",
                    systemImage: "aqi.medium",
                    text: plant.toxicPrinciples
                )
                informationCard(
                    title: "可能表现",
                    systemImage: "waveform.path.ecg",
                    text: plant.clinicalSigns
                )
                EmergencyCard()
                source
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(AppTheme.cream.ignoresSafeArea())
        .navigationTitle(plant.chineseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(plant)
                } label: {
                    Image(systemName: favorites.contains(plant) ? "heart.fill" : "heart")
                }
                .accessibilityLabel(favorites.contains(plant) ? "取消收藏" : "收藏")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.moss.opacity(0.38), AppTheme.warning.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "leaf.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.forest)
            }
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 5) {
                Text(plant.chineseName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(plant.englishName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.forest)
                Text(plant.scientificName)
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
                Text(plant.family)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var toxicityOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("毒性对象", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.danger)

            HStack(spacing: 10) {
                ForEach(PetType.allCases) { pet in
                    VStack(spacing: 6) {
                        Text(pet.emoji)
                            .font(.title2)
                        Text(pet.title)
                            .font(.caption.weight(.semibold))
                        Text(plant.isToxic(to: pet) ? "有毒" : "未列出")
                            .font(.caption2)
                            .foregroundStyle(plant.isToxic(to: pet) ? AppTheme.danger : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        plant.isToxic(to: pet) ? AppTheme.danger.opacity(0.09) : Color.secondary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
            }

            Text("“未列出”不等于可以食用；任何植物材料都可能导致胃肠不适。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func informationCard(title: String, systemImage: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.forest)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("资料来源")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let url = URL(string: plant.sourceURL) {
                Link(destination: url) {
                    Label("查看 ASPCA 原始资料", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.medium))
                }
            }
            Text("本应用仅供风险筛查，不能替代兽医诊断。资料可能不完整，请以兽医意见为准。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
