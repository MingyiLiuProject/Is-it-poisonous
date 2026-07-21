import Foundation
import ImageIO
import UIKit
import Vision

struct PlantRecognitionObservation: Sendable {
    let identifier: String
    let confidence: Float
}

struct PlantRecognitionCandidate: Identifiable {
    let plant: Plant
    let confidence: Double
    let matchedLabel: String

    var id: String { plant.id }
}

struct PlantRecognitionResult {
    let candidates: [PlantRecognitionCandidate]
    let observedLabels: [String]
}

enum PlantRecognitionError: LocalizedError {
    case invalidImage
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取这张图片，请重新拍摄或选择其他照片。"
        case .unavailable:
            return "设备暂时无法完成图片识别。"
        }
    }
}

protocol PlantRecognizing {
    func recognize(_ image: UIImage) async throws -> PlantRecognitionResult
}

struct VisionPlantRecognizer: PlantRecognizing {
    func recognize(_ image: UIImage) async throws -> PlantRecognitionResult {
        guard let cgImage = image.cgImage else {
            throw PlantRecognitionError.invalidImage
        }

        try Task.checkCancellation()
        let observations = try await classify(
            cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation)
        )
        try Task.checkCancellation()

        let simplified = observations.prefix(16).map {
            PlantRecognitionObservation(
                identifier: $0.identifier,
                confidence: $0.confidence
            )
        }
        return PlantRecognitionMatcher.match(observations: simplified)
    }

    private func classify(
        _ image: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> [VNClassificationObservation] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNClassifyImageRequest()
                    let handler = VNImageRequestHandler(
                        cgImage: image,
                        orientation: orientation,
                        options: [:]
                    )
                    try handler.perform([request])
                    guard let results = request.results else {
                        throw PlantRecognitionError.unavailable
                    }
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum PlantRecognitionMatcher {
    private static let ignoredLabels: Set<String> = [
        "plant", "plants", "flower", "flowers", "flora", "leaf", "leaves",
        "tree", "trees", "herb", "herbs", "houseplant", "houseplants",
        "vegetation", "garden", "botany"
    ]

    static func match(
        observations: [PlantRecognitionObservation],
        plants: [Plant] = PlantRepository.plants
    ) -> PlantRecognitionResult {
        let usefulObservations = observations
            .filter { $0.confidence >= 0.05 }
            .flatMap(expand)
            .filter { !ignoredLabels.contains($0.label) && $0.label.count >= 3 }

        let observedLabels = Array(
            usefulObservations
                .map(\.displayLabel)
                .reduce(into: [String]()) { labels, label in
                    if !labels.contains(label) {
                        labels.append(label)
                    }
                }
                .prefix(5)
        )

        var bestMatches: [String: PlantRecognitionCandidate] = [:]

        for plant in plants {
            let terms = Set(plant.searchTerms.map(normalize).filter { !$0.isEmpty })

            for observation in usefulObservations {
                let matchStrength: Double
                if terms.contains(observation.label) {
                    matchStrength = 1
                } else if terms.contains(where: {
                    $0.hasPrefix(observation.label + " ") ||
                    observation.label.hasPrefix($0 + " ")
                }) {
                    matchStrength = 0.82
                } else {
                    continue
                }

                let score = min(max(Double(observation.confidence) * matchStrength, 0), 1)
                guard score >= 0.08 else { continue }

                let candidate = PlantRecognitionCandidate(
                    plant: plant,
                    confidence: score,
                    matchedLabel: observation.displayLabel
                )
                if score > (bestMatches[plant.id]?.confidence ?? 0) {
                    bestMatches[plant.id] = candidate
                }
            }
        }

        let candidates = bestMatches.values
            .sorted {
                if $0.confidence == $1.confidence {
                    return $0.plant.chineseName < $1.plant.chineseName
                }
                return $0.confidence > $1.confidence
            }
            .prefix(3)

        return PlantRecognitionResult(
            candidates: Array(candidates),
            observedLabels: observedLabels
        )
    }

    private static func expand(
        _ observation: PlantRecognitionObservation
    ) -> [(label: String, displayLabel: String, confidence: Float)] {
        observation.identifier
            .split(whereSeparator: { ",;/".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map {
                (
                    label: normalize($0),
                    displayLabel: $0,
                    confidence: observation.confidence
                )
            }
    }

    private static func normalize(_ value: String) -> String {
        let folded = value
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(String(scalar)) : " "
        }
        return String(scalars)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
