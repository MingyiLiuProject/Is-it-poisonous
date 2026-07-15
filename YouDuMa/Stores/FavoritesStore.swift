import Combine
import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(ids), forKey: storageKey)
        }
    }

    private let storageKey = "favoritePlantIDs"

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? [])
    }

    func contains(_ plant: Plant) -> Bool {
        ids.contains(plant.id)
    }

    func toggle(_ plant: Plant) {
        if ids.contains(plant.id) {
            ids.remove(plant.id)
        } else {
            ids.insert(plant.id)
        }
    }
}
