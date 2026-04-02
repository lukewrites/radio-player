import SwiftUI
import RadioPlayer

struct EpisodeRowView: View {
    let episode: Episode
    let onPlay: () -> Void
    let onDownload: () -> Void

    @Environment(DownloadManager.self) private var downloadManager

    private static let broadcastDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator
                .frame(width: 10, height: 10)

            Button(action: onPlay) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.title ?? episode.filename)
                        .font(.subheadline)
                        .fontWeight(episode.episodeStatus == .new ? .medium : .regular)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        if let date = episode.broadcastDate {
                            Text(Self.broadcastDateFormatter.string(from: date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let duration = episode.duration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if episode.episodeStatus == .inProgress, let duration = episode.duration, duration > 0 {
                            ProgressView(value: episode.playbackPosition / duration)
                                .frame(width: 60)
                                .tint(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            downloadButton
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch episode.episodeStatus {
        case .new:
            Circle().fill(.blue)
        case .inProgress:
            Circle().fill(.orange)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 12))
        case .notListened:
            Circle().fill(.clear)
        }
    }

    @ViewBuilder
    private var downloadButton: some View {
        if episode.isDownloaded {
            Image(systemName: "checkmark.icloud.fill")
                .foregroundStyle(.green)
                .font(.title3)
        } else if downloadManager.isDownloading(episode) {
            let progress = downloadManager.progress(for: episode)
            CircularProgressView(fraction: progress?.fractionCompleted ?? 0)
                .frame(width: 24, height: 24)
        } else {
            Button {
                onDownload()
            } label: {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }
}

struct CircularProgressView: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.3), lineWidth: 2)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
