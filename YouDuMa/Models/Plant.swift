import Foundation

struct Plant: Identifiable, Codable, Hashable {
    let id: String
    let chineseName: String
    let englishName: String
    let scientificName: String
    let family: String
    let aliases: [String]
    let toxicTo: Set<PetType>
    let nonToxicTo: Set<PetType>
    let toxicPrinciples: String
    let clinicalSigns: String
    let sourceURL: String

    init(
        id: String,
        chineseName: String,
        englishName: String,
        scientificName: String,
        family: String,
        aliases: [String],
        toxicTo: Set<PetType>,
        nonToxicTo: Set<PetType> = [],
        toxicPrinciples: String,
        clinicalSigns: String,
        sourceURL: String
    ) {
        self.id = id
        self.chineseName = chineseName
        self.englishName = englishName
        self.scientificName = scientificName
        self.family = family
        self.aliases = aliases
        self.toxicTo = toxicTo
        self.nonToxicTo = nonToxicTo
        self.toxicPrinciples = toxicPrinciples
        self.clinicalSigns = clinicalSigns
        self.sourceURL = sourceURL
    }

    var searchableText: String {
        ([chineseName, englishName, scientificName, family] + aliases)
            .joined(separator: " ")
    }

    func isToxic(to pet: PetType) -> Bool {
        toxicTo.contains(pet)
    }

    func isListedNonToxic(to pet: PetType) -> Bool {
        nonToxicTo.contains(pet)
    }
}
