import SwiftUI

@main
struct YouDuMaApp: App {
    @StateObject private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(favorites)
                .tint(AppTheme.forest)
        }
    }
}
