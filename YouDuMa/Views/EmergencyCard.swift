import SwiftUI

struct EmergencyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("疑似误食？", systemImage: "cross.case.fill")
                .font(.title3.bold())

            Text("立即让宠物远离植物，防止继续舔食。不要自行催吐、喂食或用药，尽快联系兽医或附近的急诊兽医院。")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://maps.apple.com/?q=emergency%20veterinarian")!) {
                Label("在地图中查找附近急诊兽医", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(AppTheme.hairline)
                    }
                    .foregroundStyle(AppTheme.danger)
            }
            .buttonStyle(PressableControlButtonStyle())

            Text("如果出现呼吸或吞咽困难、抽搐、虚脱、意识异常或持续严重呕吐，不要等待，直接前往急诊兽医院。")
                .font(.caption2)
                .opacity(0.78)
        }
        .padding(18)
        .foregroundStyle(AppTheme.danger)
        .background(AppTheme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.danger.opacity(0.18))
        }
        .shadow(color: Color.black.opacity(0.045), radius: 12, y: 5)
    }
}
