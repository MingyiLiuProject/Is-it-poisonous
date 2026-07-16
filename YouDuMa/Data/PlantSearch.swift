import Foundation

struct PlantSearchIndex {
    let plant: Plant
    private let terms: Set<String>

    init(plant: Plant) {
        self.plant = plant

        var sourceTerms = plant.searchTerms
        for chineseTerm in [plant.chineseName] + plant.chineseAliases {
            if let latin = chineseTerm.applyingTransform(.toLatin, reverse: false) {
                sourceTerms.append(latin)
                let initials = latin
                    .split(whereSeparator: { !$0.isLetter })
                    .compactMap(\.first)
                if !initials.isEmpty {
                    sourceTerms.append(String(initials))
                }
            }
        }

        var indexedTerms = Set<String>()
        for sourceTerm in sourceTerms {
            for candidate in Self.normalizedVariants(sourceTerm) {
                indexedTerms.insert(candidate)
            }
            for token in sourceTerm.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                for candidate in Self.normalizedVariants(String(token)) {
                    indexedTerms.insert(candidate)
                }
            }
        }
        terms = indexedTerms
    }

    func score(for rawQuery: String) -> Int? {
        let queries = Self.normalizedVariants(rawQuery)
        guard !queries.isEmpty else {
            return 0
        }

        var bestScore: Int?
        for query in queries {
            for term in terms {
                let score: Int?
                if term == query {
                    score = 1_000
                } else if term.hasPrefix(query) {
                    score = 900
                } else if term.contains(query) {
                    score = 750
                } else {
                    score = Self.fuzzyScore(query: query, term: term)
                }

                if let score {
                    bestScore = max(bestScore ?? score, score)
                }
            }
        }
        return bestScore
    }

    private static func normalizedVariants(_ value: String) -> Set<String> {
        let umlautNormalized = value
            .replacingOccurrences(of: "ü", with: "v")
            .replacingOccurrences(of: "Ü", with: "v")
        let folded = umlautNormalized.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "zh_Hans")
        )
        let compact = folded.lowercased().filter { character in
            character.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0)
            }
        }

        guard !compact.isEmpty else {
            return []
        }

        return [compact, compact.replacingOccurrences(of: "v", with: "u")]
    }

    private static func fuzzyScore(query: String, term: String) -> Int? {
        let queryLength = query.count
        let containsHan = query.unicodeScalars.contains {
            (0x3400...0x9FFF).contains(Int($0.value))
        }
        guard queryLength >= 4 || (containsHan && queryLength >= 2) else {
            return nil
        }

        let maximumDistance: Int
        if queryLength <= 4 {
            maximumDistance = 1
        } else if queryLength <= 8 {
            maximumDistance = 2
        } else {
            maximumDistance = 3
        }

        guard abs(queryLength - term.count) <= maximumDistance else {
            return nil
        }
        let distance = levenshteinDistance(query, term, limit: maximumDistance)
        guard distance <= maximumDistance else {
            return nil
        }
        return 600 - distance * 60
    }

    private static func levenshteinDistance(
        _ lhs: String,
        _ rhs: String,
        limit: Int
    ) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        var previous = Array(0...right.count)

        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            var rowMinimum = current[0]

            for (rightIndex, rightCharacter) in right.enumerated() {
                let insertion = current[rightIndex] + 1
                let deletion = previous[rightIndex + 1] + 1
                let substitution = previous[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                let value = min(insertion, min(deletion, substitution))
                current.append(value)
                rowMinimum = min(rowMinimum, value)
            }

            if rowMinimum > limit {
                return limit + 1
            }
            previous = current
        }
        return previous[right.count]
    }
}
