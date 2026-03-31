import Foundation
import SwiftData
import Observation

@Observable
@MainActor
public final class ShowDetailViewModel {
    public var episodes: [Episode] = []
    public var isLoading = false
    public var errorMessage: String?
    public var filterStatus: EpisodeStatus?

    public var filteredEpisodes: [Episode] {
        guard let filterStatus else { return episodes }
        return episodes.filter { $0.episodeStatus == filterStatus }
    }

    private let show: Show
    private let api: ArchiveAPI
    private let modelContext: ModelContext

    public init(show: Show, api: ArchiveAPI, modelContext: ModelContext) {
        self.show = show
        self.api = api
        self.modelContext = modelContext
    }

    public func loadEpisodes() async {
        isLoading = true
        errorMessage = nil

        do {
            let metadata = try await api.fetchItemMetadata(show.identifier)
            let audioFiles = metadata.files.filter(\.isPlayableAudio)

            let existingByFilename = Dictionary(
                uniqueKeysWithValues: show.episodes.map { ($0.filename, $0) }
            )

            var result: [Episode] = []

            for file in audioFiles {
                if let existing = existingByFilename[file.name] {
                    // Update metadata but preserve user state
                    existing.title = file.title ?? existing.title
                    existing.track = file.track ?? existing.track
                    existing.duration = file.length.flatMap(Double.init) ?? existing.duration
                    existing.fileSize = file.size.flatMap(Int64.init) ?? existing.fileSize
                    result.append(existing)
                } else {
                    let episode = Episode(filename: file.name, format: file.format ?? "Unknown")
                    episode.title = file.title
                    episode.track = file.track
                    episode.duration = file.length.flatMap(Double.init)
                    episode.fileSize = file.size.flatMap(Int64.init)
                    show.episodes.append(episode)
                    result.append(episode)
                }
            }

            // Sort by track number, then filename
            result.sort { lhs, rhs in
                if let lt = lhs.track, let rt = rhs.track, lt != rt {
                    return lt.localizedStandardCompare(rt) == .orderedAscending
                }
                return lhs.filename.localizedStandardCompare(rhs.filename) == .orderedAscending
            }

            try modelContext.save()
            episodes = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
