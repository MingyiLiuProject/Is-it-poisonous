import SwiftUI

struct PlantDetailView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var favorites: FavoritesStore
    let plant: Plant

    private var isFavorite: Bool {
        favorites.contains(plant)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                namingOverview
                toxicityOverview
                if plant.toxicPrinciples.isEmpty && plant.clinicalSigns.isEmpty {
                    informationCard(
                        title: "详细资料",
                        systemImage: "doc.text.magnifyingglass",
                        text: "数据库 v3 已收录毒性状态与植物分类信息。毒性成分和临床表现尚未完成中文专业审核，请通过页面底部的来源链接查看 ASPCA 详情。"
                    )
                } else {
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
                }
                EmergencyCard(plantName: plant.chineseName)
                source
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [AppTheme.cream, AppTheme.moss.opacity(0.045)],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(plant.chineseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(AppMotion.emphasized(reduceMotion: reduceMotion)) {
                        favorites.toggle(plant)
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(isFavorite ? AppTheme.danger : AppTheme.forest)
                }
                .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
                .buttonStyle(PressableControlButtonStyle())
                .sensoryFeedback(.selection, trigger: isFavorite)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                PlantRemoteImage(
                    url: plant.image?.thumbnail,
                    accessibilityLabel: "\(plant.chineseName)植物照片"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.16))
                }
                .shadow(color: Color.black.opacity(0.11), radius: 18, y: 9)

                if plant.image?.needsReview == true {
                    Label("图片待复核", systemImage: "photo.badge.exclamationmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(12)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(plant.chineseName)
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .tracking(-0.4)
                Text(plant.englishName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.forest)
                Text(plant.acceptedScientificName)
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
                Text(plant.family)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if plant.nameNeedsReview {
                    Label("名称待专业复核", systemImage: "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.warning)
                }
            }
        }
    }

    private var namingOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("名称", systemImage: "text.book.closed")
                .font(.headline)
                .foregroundStyle(AppTheme.forest)

            nameLine(title: "中文俗名", value: plant.chineseName)
            if !plant.chineseAliases.isEmpty {
                nameLine(title: "中文别名", value: plant.chineseAliases.joined(separator: "、"))
            }
            nameLine(title: "英文俗名", value: plant.englishName)
            nameLine(title: "专业学名", value: plant.acceptedScientificName, italic: true)
            if !plant.scientificName.isEmpty &&
                plant.scientificName != plant.acceptedScientificName {
                nameLine(title: "ASPCA 记录名", value: plant.scientificName, italic: true)
            }

            if plant.nameNeedsReview {
                Text("该中文名或学名由自动匹配/翻译补全，尚待植物学专业人员复核。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .appCard()
    }

    private func nameLine(title: String, value: String, italic: Bool = false) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 82, alignment: .leading)
                Text(value)
                    .font(italic ? Font.subheadline.italic() : Font.subheadline)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(italic ? Font.subheadline.italic() : Font.subheadline)
                    .textSelection(.enabled)
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
                        Text(statusTitle(for: pet))
                            .font(.caption2)
                            .foregroundStyle(plant.isToxic(to: pet) ? AppTheme.danger : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        plant.isToxic(to: pet) ? AppTheme.danger.opacity(0.10) : AppTheme.elevated,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                plant.isToxic(to: pet)
                                    ? AppTheme.danger.opacity(0.16)
                                    : AppTheme.hairline
                            )
                    }
                }
            }

            Text("“未列出”不等于可以食用；任何植物材料都可能导致胃肠不适。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .appCard()
    }

    private func statusTitle(for pet: PetType) -> String {
        if plant.isToxic(to: pet) {
            return "有毒"
        }
        if plant.isListedNonToxic(to: pet) {
            return "列为无毒"
        }
        return "未列出"
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
        .appCard()
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("资料来源")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let url = URL(string: plant.sourceURL) {
                Link(destination: url) {
                    Label("查看 ASPCA 原始资料", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.medium))
                }
            }
            if let image = plant.image {
                Divider()
                Text("植物图片")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let sourcePage = image.sourcePage {
                    Link(destination: sourcePage) {
                        Label("查看 Wikimedia Commons 图片页面", systemImage: "photo")
                            .font(.subheadline.weight(.medium))
                    }
                }
                Text("作者：\(image.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let licensePage = image.licensePage {
                    Link("许可：\(image.license)", destination: licensePage)
                        .font(.caption)
                } else {
                    Text("许可：\(image.license)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if image.needsReview {
                    Text("该图片通过学名或俗名搜索匹配，仍需人工确认是否为准确物种。")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warning)
                }
            }
            Text("本应用仅供风险筛查，不能替代兽医诊断。资料可能不完整，请以兽医意见为准。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCard()
    }
}
