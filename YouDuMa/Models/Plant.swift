import Foundation

struct Plant: Identifiable, Codable, Hashable {
    let id: String
    let chineseName: String
    let englishName: String
    let scientificName: String
    let family: String
    let aliases: [String]
    let toxicTo: Set<PetType>
    let toxicPrinciples: String
    let clinicalSigns: String
    let sourceURL: String

    var searchableText: String {
        ([chineseName, englishName, scientificName, family] + aliases)
            .joined(separator: " ")
    }

    func isToxic(to pet: PetType) -> Bool {
        toxicTo.contains(pet)
    }
}
