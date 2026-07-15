import Foundation

enum PlantRepository {
    static let plants: [Plant] = {
        var catalog = Dictionary(uniqueKeysWithValues: loadCatalog().map { ($0.id, $0) })
        for reviewedPlant in reviewedPlants {
            if let importedPlant = catalog[reviewedPlant.id] {
                catalog[reviewedPlant.id] = reviewedPlant.withStatuses(from: importedPlant)
            } else {
                catalog[reviewedPlant.id] = reviewedPlant
            }
        }
        return catalog.values.sorted {
            $0.englishName.localizedCaseInsensitiveCompare($1.englishName) == .orderedAscending
        }
    }()

    private static let reviewedPlants: [Plant] = [
        Plant(
            id: "lily",
            chineseName: "百合",
            englishName: "Lily",
            scientificName: "Lilium species",
            family: "Liliaceae",
            aliases: ["真百合", "亚洲百合", "Asiatic Lily"],
            toxicTo: [.cat],
            toxicPrinciples: "ASPCA 将毒性成分列为未知。",
            clinicalSigns: "猫可能出现呕吐、食欲下降、嗜睡和肾衰竭。花、叶、花粉以及花瓶水都应视为潜在暴露来源。",
            sourceURL: "https://www.aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants/lily"
        ),
        Plant(
            id: "sago-palm",
            chineseName: "苏铁",
            englishName: "Sago Palm",
            scientificName: "Cycas revoluta",
            family: "Cycadaceae",
            aliases: ["铁树", "凤尾蕉", "Japanese Sago Palm"],
            toxicTo: [.cat, .dog, .horse],
            toxicPrinciples: "苏铁苷（Cycasin）。整株有毒，种子中的毒素浓度尤其高。",
            clinicalSigns: "可能出现呕吐、血便、黄疸、凝血异常、肝损伤、肝衰竭，严重时可致死。",
            sourceURL: "https://www.aspca.org/news/dangers-sago-palm"
        ),
        Plant(
            id: "aloe",
            chineseName: "芦荟",
            englishName: "Aloe",
            scientificName: "Aloe vera",
            family: "Liliaceae",
            aliases: ["Aloe Vera", "真芦荟"],
            toxicTo: [.cat, .dog, .horse],
            toxicPrinciples: "皂苷、蒽醌类；透明凝胶与外层乳汁的风险不同。",
            clinicalSigns: "可能出现呕吐（马除外）、嗜睡和腹泻。",
            sourceURL: "https://www.aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants/aloe"
        ),
        Plant(
            id: "azalea",
            chineseName: "杜鹃花",
            englishName: "Azalea",
            scientificName: "Rhododendron species",
            family: "Ericaceae",
            aliases: ["映山红", "Rhododendron"],
            toxicTo: [.cat, .dog, .horse],
            toxicPrinciples: "灰安毒素（Grayanotoxins）。",
            clinicalSigns: "常见为流涎、呕吐或腹泻、虚弱；摄入量较大时可能出现心律异常、低血压、震颤或癫痫。",
            sourceURL: "https://www.aspca.org/news/top-10-toxic-plants-pets-what-look-out"
        ),
        Plant(
            id: "tulip",
            chineseName: "郁金香",
            englishName: "Tulip",
            scientificName: "Tulipa species",
            family: "Liliaceae",
            aliases: ["Tulipa"],
            toxicTo: [.cat, .dog, .horse],
            toxicPrinciples: "郁金香苷 A、B；球茎中的浓度最高。",
            clinicalSigns: "可能出现流涎、呕吐、腹泻和口腔刺激；吞下较大球茎还可能造成消化道梗阻。",
            sourceURL: "https://www.aspca.org/news/gardening-safety-101-your-guide-keeping-your-pet-safe"
        ),
        Plant(
            id: "pothos",
            chineseName: "绿萝",
            englishName: "Pothos",
            scientificName: "Epipremnum aureum",
            family: "Araceae",
            aliases: ["黄金葛", "Devil's Ivy", "Golden Pothos"],
            toxicTo: [.cat, .dog],
            toxicPrinciples: "不溶性草酸钙晶体。",
            clinicalSigns: "咀嚼后可能引起口腔疼痛和刺激、流涎、干呕、呕吐或吞咽困难。",
            sourceURL: "https://www.aspca.org/news/houseplant-safe-your-pets"
        ),
        Plant(
            id: "peace-lily",
            chineseName: "白鹤芋",
            englishName: "Peace Lily",
            scientificName: "Spathiphyllum species",
            family: "Araceae",
            aliases: ["和平百合", "白掌", "Spathiphyllum"],
            toxicTo: [.cat, .dog],
            toxicPrinciples: "不溶性草酸钙晶体。它不属于会导致猫急性肾损伤的真百合属。",
            clinicalSigns: "可能出现口腔刺激、流涎、口腔疼痛、呕吐和胃肠不适。",
            sourceURL: "https://www.aspca.org/news/top-10-toxic-plants-pets-what-look-out"
        ),
        Plant(
            id: "monstera",
            chineseName: "龟背竹",
            englishName: "Monstera",
            scientificName: "Monstera deliciosa",
            family: "Araceae",
            aliases: ["Swiss Cheese Plant", "蓬莱蕉"],
            toxicTo: [.cat, .dog],
            toxicPrinciples: "不溶性草酸钙晶体。",
            clinicalSigns: "可能出现口腔刺激、舌唇灼痛、流涎、呕吐或吞咽困难。",
            sourceURL: "https://www.aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants"
        ),
        Plant(
            id: "snake-plant",
            chineseName: "虎尾兰",
            englishName: "Snake Plant",
            scientificName: "Dracaena trifasciata",
            family: "Asparagaceae",
            aliases: ["虎皮兰", "Mother-in-Law's Tongue", "Sansevieria trifasciata"],
            toxicTo: [.cat, .dog],
            toxicPrinciples: "皂苷。",
            clinicalSigns: "猫或狗摄入后可能出现呕吐、腹泻、流涎和嗜睡。",
            sourceURL: "https://www.aspca.org/news/are-succulents-safe-have-around-pets"
        ),
        Plant(
            id: "oleander",
            chineseName: "夹竹桃",
            englishName: "Oleander",
            scientificName: "Nerium oleander",
            family: "Apocynaceae",
            aliases: ["Nerium"],
            toxicTo: [.cat, .dog, .horse],
            toxicPrinciples: "强心苷。",
            clinicalSigns: "可能出现流涎、腹痛、腹泻、抑郁及心律异常，严重时可能致死。",
            sourceURL: "https://www.aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants/oleander"
        ),
        Plant(
            id: "hydrangea",
            chineseName: "绣球花",
            englishName: "Hydrangea",
            scientificName: "Hydrangea arborescens",
            family: "Hydrangeaceae",
            aliases: ["八仙花", "Hydrangea"],
            toxicTo: [.cat, .dog, .horse],
            toxicPrinciples: "氰苷。",
            clinicalSigns: "猫狗摄入后更常见的是呕吐、腹泻等胃肠道症状；仍应联系兽医评估。",
            sourceURL: "https://www.aspca.org/news/top-10-toxic-plants-pets-what-look-out"
        ),
        Plant(
            id: "jade-plant",
            chineseName: "玉树",
            englishName: "Jade Plant",
            scientificName: "Crassula ovata",
            family: "Crassulaceae",
            aliases: ["燕子掌", "Money Plant", "Lucky Plant"],
            toxicTo: [.cat, .dog],
            toxicPrinciples: "ASPCA 将毒性成分列为未知。",
            clinicalSigns: "可能出现呕吐、腹泻、嗜睡、步态不稳或肌肉震颤。",
            sourceURL: "https://www.aspca.org/news/are-succulents-safe-have-around-pets"
        )
    ]

    private static func loadCatalog() -> [Plant] {
        let catalogURL = Bundle.main.url(
            forResource: "aspca_plants_v1",
            withExtension: "json",
            subdirectory: "Data"
        ) ?? Bundle.main.url(
            forResource: "aspca_plants_v1",
            withExtension: "json"
        )

        guard let url = catalogURL else {
            assertionFailure("Missing ASPCA plant catalog resource")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Plant].self, from: data)
        } catch {
            assertionFailure("Could not decode ASPCA plant catalog: \(error)")
            return []
        }
    }

    static func search(_ query: String, pet: PetType? = nil) -> [Plant] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return plants.filter { plant in
            let matchesPet = pet.map { plant.toxicTo.contains($0) } ?? true
            let matchesQuery = trimmed.isEmpty || plant.searchableText.localizedCaseInsensitiveContains(trimmed)
            return matchesPet && matchesQuery
        }
    }
}

private extension Plant {
    func withStatuses(from importedPlant: Plant) -> Plant {
        Plant(
            id: id,
            chineseName: chineseName,
            englishName: englishName,
            scientificName: scientificName,
            family: family,
            aliases: Array(Set(aliases + importedPlant.aliases)).sorted(),
            toxicTo: importedPlant.toxicTo,
            nonToxicTo: importedPlant.nonToxicTo,
            toxicPrinciples: toxicPrinciples,
            clinicalSigns: clinicalSigns,
            sourceURL: importedPlant.sourceURL
        )
    }
}
