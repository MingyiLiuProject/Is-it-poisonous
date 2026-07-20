import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("查询", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("收藏", systemImage: "heart")
                }

            SafetyView()
                .tabItem {
                    Label("应急", systemImage: "cross.case")
                }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
