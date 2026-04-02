import SwiftUI
import RadioPlayer

struct FullPlayerView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(SleepTimer.self) private var sleepTimer
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Large artwork
                AsyncCachedImage(
                    url: player.currentEpisode?.show?.thumbnailImageURL,
                    title: player.currentEpisode?.show?.title ?? "",
                    size: 260
                )
                .padding(.top, 20)

                // Title
                VStack(spacing: 4) {
                    Text(player.currentEpisode?.title ?? player.currentEpisode?.filename ?? "")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(player.currentEpisode?.show?.title ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Scrubber
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { player.duration > 0 ? player.currentTime / player.duration : 0 },
                            set: { player.seekTo($0 * player.duration) }
                        )
                    )

                    HStack {
                        Text(formatDuration(player.currentTime))
                        Spacer()
                        Text(player.duration > 0 ? "-\(formatDuration(player.duration - player.currentTime))" : "--:--")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Main controls
                HStack(spacing: 44) {
                    Button { player.skipBackward() } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 28))
                    }

                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                    }

                    Button { player.skipForward() } label: {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 28))
                    }
                }
                .foregroundStyle(.primary)

                // Speed picker
                Picker("Speed", selection: Binding(
                    get: { player.playbackRate },
                    set: { player.playbackRate = $0 }
                )) {
                    Text("0.5×").tag(Float(0.5))
                    Text("1×").tag(Float(1.0))
                    Text("1.25×").tag(Float(1.25))
                    Text("1.5×").tag(Float(1.5))
                    Text("2×").tag(Float(2.0))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // AirPlay
                HStack {
                    Spacer()
                    AirPlayButton()
                        .frame(width: 36, height: 36)
                    Spacer()
                }

                // Sleep timer
                sleepTimerRow
                    .padding(.bottom, 16)

                Spacer(minLength: 0)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .background {
                if !theme.playerGradientColors.isEmpty {
                    LinearGradient(
                        colors: theme.playerGradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .modify { view in
            if theme.forceDarkPlayer {
                view.environment(\.colorScheme, .dark)
            } else {
                view
            }
        }
    }

    @ViewBuilder
    private var sleepTimerRow: some View {
        HStack {
            Image(systemName: "moon.zzz")
                .foregroundStyle(.secondary)

            if sleepTimer.isActive {
                Text(sleepTimer.formattedRemaining)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                Spacer()
                Button("Cancel") { sleepTimer.cancel() }
                    .foregroundStyle(.orange)
            } else {
                Text("Sleep Timer")
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    ForEach(SleepTimer.presets, id: \.self) { minutes in
                        Button("\(minutes) min") {
                            sleepTimer.start(minutes: minutes)
                        }
                    }
                } label: {
                    Text("Set")
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal)
    }
}
