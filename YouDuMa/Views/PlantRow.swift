import SwiftUI

struct PlantRow: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.moss.opacity(0.32), AppTheme.forest.opacity(0.13)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.forest)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.chineseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(plant.englishName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(plant.scientificName)
                    .font(.caption.italic())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 7) {
                Text(plant.toxicTo.map(\.emoji).sorted().joined())
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.danger.opacity(0.11), in: Capsule())
                    .accessibilityLabel("有毒对象：\(plant.toxicTo.map(\.title).joined(separator: "、"))")
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.8))
        }
    }
}
