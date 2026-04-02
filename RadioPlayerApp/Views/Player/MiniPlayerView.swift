import SwiftUI
import RadioPlayer

struct MiniPlayerView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(\.appTheme) private var theme
    @State private var showFullPlayer = false

    var body: some View {
        HStack(spacing: 12) {
            // Tapping the artwork/title area opens the full player
            Button {
                showFullPlayer = true
            } label: {
                HStack(spacing: 12) {
                    AsyncCachedImage(
                        url: player.currentEpisode?.show?.thumbnailImageURL,
                        title: player.currentEpisode?.show?.title ?? "Now Playing",
                        size: 44
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.currentEpisode?.title ?? player.currentEpisode?.filename ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(player.currentEpisode?.show?.title ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open full player")
            .accessibilityIdentifier("miniPlayer")

            // Controls
            HStack(spacing: 20) {
                Button {
                    player.skipBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title3)
                }

                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                Button {
                    player.skipForward()
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.title3)
                }
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 2)
        .overlay(alignment: .bottom) {
            // Progress bar
            if player.duration > 0 {
                GeometryReader { geo in
                    Rectangle()
                        .fill(theme.accent.opacity(0.7))
                        .frame(width: geo.size.width * (player.currentTime / player.duration), height: 2)
                }
                .frame(height: 2)
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
