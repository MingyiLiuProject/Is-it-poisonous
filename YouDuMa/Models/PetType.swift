import SwiftUI

enum PetType: String, CaseIterable, Codable, Hashable, Identifiable {
    case cat
    case dog
    case horse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cat: "猫"
        case .dog: "狗"
        case .horse: "马"
        }
    }

    var emoji: String {
        switch self {
        case .cat: "🐱"
        case .dog: "🐶"
        case .horse: "🐴"
        }
    }
}
