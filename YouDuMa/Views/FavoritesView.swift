import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore

    private var plants: [Plant] {
        PlantRepository.plants.filter(favorites.contains)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

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
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("我的收藏")
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
        }
    }
}
