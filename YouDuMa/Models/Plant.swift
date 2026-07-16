import Foundation

struct Plant: Identifiable, Codable, Hashable {
    let id: String
    let chineseName: String
    let chineseAliases: [String]
    let englishName: String
    let scientificName: String
    let acceptedScientificName: String
    let family: String
    let aliases: [String]
    let pinyin: [String]
    let nameSource: String
    let nameNeedsReview: Bool
    let toxicTo: Set<PetType>
    let nonToxicTo: Set<PetType>
    let toxicPrinciples: String
    let clinicalSigns: String
    let sourceURL: String

    init(
        id: String,
        chineseName: String,
        chineseAliases: [String] = [],
        englishName: String,
        scientificName: String,
        acceptedScientificName: String? = nil,
        family: String,
        aliases: [String],
        pinyin: [String] = [],
        nameSource: String = "reviewed",
        nameNeedsReview: Bool = false,
        toxicTo: Set<PetType>,
        nonToxicTo: Set<PetType> = [],
        toxicPrinciples: String,
        clinicalSigns: String,
        sourceURL: String
    ) {
        self.id = id
        self.chineseName = chineseName
        self.chineseAliases = chineseAliases
        self.englishName = englishName
        self.scientificName = scientificName
        self.acceptedScientificName = acceptedScientificName ?? scientificName
        self.family = family
        self.aliases = aliases
        self.pinyin = pinyin
        self.nameSource = nameSource
        self.nameNeedsReview = nameNeedsReview
        self.toxicTo = toxicTo
        self.nonToxicTo = nonToxicTo
        self.toxicPrinciples = toxicPrinciples
        self.clinicalSigns = clinicalSigns
        self.sourceURL = sourceURL
    }

    var searchTerms: [String] {
        [
            chineseName,
            englishName,
            scientificName,
            acceptedScientificName,
            family
        ] + chineseAliases + aliases + pinyin
    }

    func isToxic(to pet: PetType) -> Bool {
        toxicTo.contains(pet)
    }

    func isListedNonToxic(to pet: PetType) -> Bool {
        nonToxicTo.contains(pet)
    }
}
