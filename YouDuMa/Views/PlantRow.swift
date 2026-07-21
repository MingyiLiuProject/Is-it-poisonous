import SwiftUI

struct PlantRow: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: 14) {
            PlantRemoteImage(
                url: plant.image?.thumbnail,
                accessibilityLabel: "\(plant.chineseName)植物照片"
            )
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.chineseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(plant.englishName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(plant.acceptedScientificName)
                    .font(.caption.italic())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 7) {
                if plant.toxicTo.isEmpty {
                    Text("未列有毒")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.forest)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppTheme.moss.opacity(0.14), in: Capsule())
                } else {
                    Text(plant.toxicTo.map(\.emoji).sorted().joined())
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.danger.opacity(0.11), in: Capsule())
                        .accessibilityLabel("有毒对象：\(plant.toxicTo.map(\.title).joined(separator: "、"))")
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .appCard()
    }
}
