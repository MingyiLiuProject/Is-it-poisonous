import SwiftUI

struct SafetyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EmergencyCard()

                    section(
                        title: "立即处理",
                        systemImage: "figure.walk.motion",
                        items: [
                            "将宠物和其他动物带离植物，防止继续舔食或接触花粉、叶片与花瓶水",
                            "在确保自身安全的情况下收起剩余植物；处理汁液后清洗双手",
                            "拍摄植物整体、叶片、花和标签，保留少量样本供兽医识别",
                            "记录接触时间、可能摄入的部位和最大数量，并尽快联系兽医"
                        ],
                        itemSystemImage: "checkmark.circle.fill",
                        accent: AppTheme.moss
                    )

                    section(
                        title: "不要自行处理",
                        systemImage: "hand.raised.fill",
                        items: [
                            "除非兽医明确指示，不要自行催吐；某些物质在呕吐时会造成二次伤害",
                            "不要强行喂水、牛奶、油、盐或活性炭，也不要给人用药",
                            "不要因为暂时没有症状就等待观察；一些植物的严重影响可能延迟出现",
                            "“未列为有毒”不代表适合食用，任何植物材料都可能引起胃肠不适"
                        ],
                        itemSystemImage: "xmark.octagon.fill",
                        accent: AppTheme.danger
                    )

                    section(
                        title: "立即前往急诊的情况",
                        systemImage: "exclamationmark.triangle.fill",
                        items: [
                            "呼吸困难、吞咽困难、喉头或面部肿胀",
                            "抽搐、震颤、明显步态不稳、虚脱或反应异常",
                            "持续或严重呕吐、腹泻，或呕吐物与粪便中带血",
                            "明显流涎、疼痛、极度虚弱，或牙龈变得异常苍白、发蓝或发黄",
                            "已知接触高风险植物或摄入量不确定，即使尚无症状也应尽快就医"
                        ],
                        itemSystemImage: "exclamationmark.circle.fill",
                        accent: AppTheme.danger
                    )

                    section(
                        title: "就医前准备",
                        systemImage: "cross.case",
                        items: [
                            "出发前联系兽医院，说明疑似植物中毒和当前症状",
                            "准备宠物的种类、年龄、体重、基础疾病与正在使用的药物",
                            "携带植物照片、标签或密封样本，记录摄入时间、部位和估计数量",
                            "记录症状出现与变化的时间，如果条件允许可拍摄短视频供兽医参考",
                            "使用运输箱或牵引装备安全运送；途中不喂食或给药，除非兽医明确指示"
                        ],
                        itemSystemImage: "checkmark.circle.fill",
                        accent: AppTheme.forest
                    )

                    Link(destination: URL(string: "https://maps.apple.com/?q=emergency%20veterinarian")!) {
                        Label("在地图中查找附近急诊兽医", systemImage: "map.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .foregroundStyle(.white)
                            .background(AppTheme.forestFill, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(PressableControlButtonStyle())

                    VStack(alignment: .leading, spacing: 10) {
                        Text("急救信息来源")
                            .font(.headline)
                        Link("康奈尔大学兽医学院：中毒物质急救", destination: URL(string: "https://www.vet.cornell.edu/departments-centers-and-institutes/riney-canine-health-center/canine-health-information/first-aid-poisonous-substances")!)
                        Link("RSPCA：宠物急救与中毒症状", destination: URL(string: "https://www.rspca.org.uk/adviceandwelfare/pets/dogs/health/firstaid")!)
                        Text("本页只提供现场信息整理与就医准备，不代替兽医诊断或个体化急救指导。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .appCard()

                    Text("数据说明")
                        .font(.headline)
                    Text("数据库 v3 收录 ASPCA 猫、狗、马列表中的植物分类与毒性状态；临床描述仍在分批专业审核。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("数据库最近核对：2026-07-16 · 急救说明更新：2026-07-17")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(18)
            }
            .background(
                LinearGradient(
                    colors: [AppTheme.cream, AppTheme.moss.opacity(0.045)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("应急与说明")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    private func section(
        title: String,
        systemImage: String,
        items: [String],
        itemSystemImage: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(accent)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: itemSystemImage)
                        .foregroundStyle(accent)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCard()
    }
}
