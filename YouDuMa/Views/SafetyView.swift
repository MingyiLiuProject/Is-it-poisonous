import SwiftUI

struct SafetyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EmergencyCard()

                    section(
                        title: "联系前准备",
                        systemImage: "checklist",
                        items: [
                            "宠物的种类、体重和年龄",
                            "植物照片、名称或剩余样本",
                            "可能摄入的部位和最大数量",
                            "发生时间与已出现的症状"
                        ]
                    )

                    section(
                        title: "重要提醒",
                        systemImage: "info.circle",
                        items: [
                            "不要等待症状出现后才求助",
                            "不要自行催吐或强行喂水",
                            "“未列为有毒”不代表适合食用",
                            "同一个俗名可能对应不同物种，尽量核对学名"
                        ]
                    )

                    Text("数据说明")
                        .font(.headline)
                    Text("当前版本是产品原型，只内置少量常见植物。正式发布需要专业审核、更新日期、版本记录和可追溯的数据授权。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("示例数据最近核对：2026-07-15")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(18)
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .navigationTitle("应急与说明")
        }
    }

    private func section(title: String, systemImage: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.forest)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.moss)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
