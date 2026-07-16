import SwiftUI
import UIKit

@MainActor
private final class PlantImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var didFail = false

    private static let memoryCache = NSCache<NSURL, UIImage>()
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 64 * 1_024 * 1_024,
            diskCapacity: 256 * 1_024 * 1_024,
            diskPath: "plant-image-cache"
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }()

    func load(_ url: URL?) async {
        image = nil
        didFail = false

        guard let url else {
            didFail = true
            return
        }
        if let cached = Self.memoryCache.object(forKey: url as NSURL) {
            image = cached
            return
        }

        do {
            for attempt in 0..<3 {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.setValue(
                    "IsItPoisonous/1.0 (https://github.com/MingyiLiuProject/Is-it-poisonous)",
                    forHTTPHeaderField: "User-Agent"
                )
                request.setValue("image/jpeg", forHTTPHeaderField: "Accept")
                let (data, response) = try await Self.session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    didFail = true
                    return
                }
                if httpResponse.statusCode == 429 && attempt < 2 {
                    try await Task.sleep(
                        nanoseconds: UInt64(1 << attempt) * 1_000_000_000
                    )
                    continue
                }
                guard
                    (200..<300).contains(httpResponse.statusCode),
                    let downloadedImage = UIImage(data: data)
                else {
                    didFail = true
                    return
                }
                Self.memoryCache.setObject(downloadedImage, forKey: url as NSURL)
                image = downloadedImage
                return
            }
            didFail = true
        } catch is CancellationError {
            return
        } catch {
            didFail = true
        }
    }
}

struct PlantRemoteImage: View {
    let url: URL?
    let accessibilityLabel: String

    @StateObject private var loader = PlantImageLoader()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.moss.opacity(0.32), AppTheme.forest.opacity(0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else if loader.didFail {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.forest)
            } else {
                ProgressView()
                    .tint(AppTheme.forest)
            }
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .task(id: url) {
            await loader.load(url)
        }
    }
}
