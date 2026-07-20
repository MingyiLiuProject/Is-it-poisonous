import SwiftUI

struct FavoritesView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var favorites: FavoritesStore

    private var plants: [Plant] {
        PlantRepository.plants.filter(favorites.contains)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.cream, AppTheme.moss.opacity(0.045)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if plants.isEmpty {
                    ContentUnavailableView(
                        "还没有收藏",
                        systemImage: "heart",
                        description: Text("在植物详情页点按爱心，方便以后快速查看")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(plants) { plant in
                                NavigationLink(value: plant) {
                                    PlantRow(plant: plant)
                                }
                                .buttonStyle(PressableCardButtonStyle())
                                .transition(
                                    reduceMotion
                                        ? .opacity
                                        : .opacity.combined(with: .scale(scale: 0.97))
                                )
                            }
                        }
                        .padding(18)
                    }
                    .animation(
                        AppMotion.responsive(reduceMotion: reduceMotion),
                        value: plants.map(\.id)
                    )
                }
            }
            .navigationTitle("我的收藏")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
        }
    }
}
