import SwiftUI

struct EmergencyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("疑似误食？", systemImage: "cross.case.fill")
                .font(.title3.bold())

            Text("不要自行催吐。记录植物名称、摄入时间和大致数量，拍照并立即联系当地兽医。")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "tel:145")!) {
                Label("瑞士中毒急救 145", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .foregroundStyle(AppTheme.danger)
            }

            Link(destination: URL(string: "tel:+18884264435")!) {
                Label("ASPCA +1 888 426 4435", systemImage: "phone")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }

            Text("ASPCA 与瑞士动物中毒咨询均可能收费；危急情况优先联系就近急诊兽医。")
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
    }
}
