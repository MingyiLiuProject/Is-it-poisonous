import XCTest
@testable import YouDuMa

final class PlantSearchTests: XCTestCase {
    func testSearchesChineseEnglishAndScientificNames() {
        XCTAssertTrue(PlantRepository.search("绿萝").contains { $0.id == "devils-ivy" })
        XCTAssertTrue(PlantRepository.search("pothos").contains { $0.id == "pothos" })
        XCTAssertTrue(PlantRepository.search("Epipremnum").contains { $0.id == "devils-ivy" })
    }

    func testSearchesFullPinyinAndPinyinInitials() {
        XCTAssertTrue(PlantRepository.search("lvluo").contains { $0.id == "devils-ivy" })
        XCTAssertTrue(PlantRepository.search("gui bei zhu").contains { $0.chineseName == "龟背竹" })
        XCTAssertTrue(PlantRepository.search("lhs").contains { $0.id == "yew-pine" })
    }

    func testFuzzySearchToleratesMinorTypos() {
        XCTAssertTrue(PlantRepository.search("Epipremun").contains { $0.id == "devils-ivy" })
        XCTAssertTrue(PlantRepository.search("poths").contains { $0.id == "pothos" })
        XCTAssertTrue(PlantRepository.search("绿罗").contains { $0.id == "devils-ivy" })
    }

    func testSearchesAcceptedScientificName() {
        XCTAssertTrue(
            PlantRepository.search("Podocarpus macrophyllus")
                .contains { $0.id == "yew-pine" }
        )
    }

    func testPetFilterOnlyReturnsToxicMatches() {
        let catResults = PlantRepository.search("百合", pet: .cat)

        XCTAssertTrue(catResults.contains { $0.id == "lily" })
        XCTAssertTrue(catResults.allSatisfy { $0.toxicTo.contains(.cat) })
    }

    func testLoadsVersionedASPCAPlantCatalog() {
        XCTAssertGreaterThan(PlantRepository.plants.count, 900)
        XCTAssertTrue(PlantRepository.plants.contains { $0.nonToxicTo.isEmpty == false })
        XCTAssertTrue(PlantRepository.plants.allSatisfy { !$0.chineseName.isEmpty })
        XCTAssertTrue(PlantRepository.plants.allSatisfy { !$0.acceptedScientificName.isEmpty })
        XCTAssertTrue(PlantRepository.plants.allSatisfy { $0.image != nil })
        XCTAssertTrue(
            PlantRepository.plants.allSatisfy {
                $0.image?.thumbnailURL.hasPrefix("https://") == true
            }
        )
        XCTAssertTrue(
            PlantRepository.plants.allSatisfy {
                !($0.image?.author.isEmpty ?? true) &&
                !($0.image?.license.isEmpty ?? true)
            }
        )
    }
}
