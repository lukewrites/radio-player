import SwiftUI
import SwiftData
import RadioPlayer

struct FavoritesView: View {
    @Query(filter: #Predicate<Show> { $0.isFavorite }, sort: \Show.title) private var shows: [Show]

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)
    ]

    var body: some View {
        Group {
            if shows.isEmpty {
                ContentUnavailableView(
                    "No Favorites",
                    systemImage: "star",
                    description: Text("Open a show and tap the star to add it here.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(shows) { show in
                            NavigationLink(value: show) {
                                FavoriteShowCardView(show: show)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(show.title)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationDestination(for: Show.self) { show in
            ShowDetailView(show: show)
        }
    }
}

/// Card view for a favorited Show (mirrors ShowCardView layout without needing SearchDoc).
private struct FavoriteShowCardView: View {
    let show: Show
    var size: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncCachedImage(
                url: show.thumbnailImageURL,
                title: show.title,
                size: size
            )

            Text(show.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: size, alignment: .leading)

            if let creator = show.creator {
                Text(creator)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: size, alignment: .leading)
            }
        }
    }
}
