import Foundation

struct PlantImage: Codable, Hashable {
    let thumbnailURL: String
    let pageURL: String
    let fileTitle: String
    let author: String
    let license: String
    let licenseURL: String
    let description: String
    let source: String
    let matchType: String
    let needsReview: Bool

    var thumbnail: URL? {
        URL(string: thumbnailURL)
    }

    var sourcePage: URL? {
        URL(string: pageURL)
    }

    var licensePage: URL? {
        URL(string: licenseURL)
    }
}

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
    let image: PlantImage?

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
        sourceURL: String,
        image: PlantImage? = nil
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
        self.image = image
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
