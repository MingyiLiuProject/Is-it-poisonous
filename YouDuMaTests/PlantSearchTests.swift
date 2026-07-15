import XCTest
@testable import YouDuMa

final class PlantSearchTests: XCTestCase {
    func testSearchesChineseEnglishAndScientificNames() {
        XCTAssertEqual(PlantRepository.search("绿萝").first?.id, "pothos")
        XCTAssertEqual(PlantRepository.search("pothos").first?.id, "pothos")
        XCTAssertEqual(PlantRepository.search("Epipremnum").first?.id, "pothos")
    }

    func testPetFilterOnlyReturnsToxicMatches() {
        let catResults = PlantRepository.search("百合", pet: .cat)
        let dogResults = PlantRepository.search("百合", pet: .dog)

        XCTAssertEqual(catResults.first?.id, "lily")
        XCTAssertTrue(dogResults.isEmpty)
    }
}
