import SwiftUI

struct EmergencyCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completedActionIDs: Set<Int> = []

    let plantName: String?

    init(plantName: String? = nil) {
        self.plantName = plantName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("接触后行动", systemImage: "checklist")
                    .font(.title3.bold())

                Spacer()

                Text("\(completedActionIDs.count)/\(Self.actions.count)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(reduceMotion ? .opacity : .numericText())
            }

            Text("这些行动不必按顺序完成。出现呼吸困难、抽搐、虚脱或意识异常时，请直接前往兽医急诊。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 9) {
                ForEach(Self.actions) { action in
                    actionRow(action)
                }
            }

            Link(destination: URL(string: "https://maps.apple.com/?q=emergency%20veterinarian")!) {
                Label("查找附近兽医院", systemImage: "map.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(AppTheme.forestFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressableControlButtonStyle())

            Label("未经兽医明确指示，不要催吐、强行喂食或自行用药。", systemImage: "hand.raised.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.danger)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .appCard(cornerRadius: 22)
        .sensoryFeedback(.selection, trigger: completedActionIDs.count)
    }

    private func actionRow(_ action: ExposureAction) -> some View {
        let isCompleted = completedActionIDs.contains(action.id)

        return Button {
            withAnimation(AppMotion.responsive(reduceMotion: reduceMotion)) {
                if isCompleted {
                    completedActionIDs.remove(action.id)
                } else {
                    completedActionIDs.insert(action.id)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : action.systemImage)
                    .font(.title3)
                    .foregroundStyle(isCompleted ? AppTheme.moss : AppTheme.forest)
                    .frame(width: 24)
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(.subheadline.weight(.semibold))
                    Text(description(for: action))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(
                isCompleted ? AppTheme.moss.opacity(0.11) : AppTheme.elevated,
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isCompleted ? AppTheme.moss.opacity(0.22) : AppTheme.hairline)
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(PressableControlButtonStyle())
        .accessibilityLabel(action.title)
        .accessibilityValue(isCompleted ? "已完成" : "未完成")
        .accessibilityHint("轻点切换完成状态")
    }

    private func description(for action: ExposureAction) -> String {
        if action.id == 1, let plantName {
            return "保存“\(plantName)”页面，拍摄植物整体、叶片、花和标签。"
        }
        return action.description
    }
}

private struct ExposureAction: Identifiable {
    let id: Int
    let title: String
    let description: String
    let systemImage: String
}

private extension EmergencyCard {
    static let actions = [
        ExposureAction(
            id: 0,
            title: "隔离宠物与植物",
            description: "立即停止继续舔食或接触，并在安全情况下收起剩余植物。",
            systemImage: "figure.walk.motion"
        ),
        ExposureAction(
            id: 1,
            title: "保存植物信息",
            description: "拍摄植物整体、叶片、花和标签，必要时保留密封样本。",
            systemImage: "camera.fill"
        ),
        ExposureAction(
            id: 2,
            title: "记录接触情况",
            description: "记录时间、部位、可能摄入量，以及症状出现和变化的时间。",
            systemImage: "clock.fill"
        ),
        ExposureAction(
            id: 3,
            title: "获取专业评估",
            description: "向当地兽医提供植物资料、宠物体重、病史和当前症状。",
            systemImage: "cross.case.fill"
        )
    ]
}
