import Foundation
import SwiftData
import Observation

@Observable
@MainActor
public final class LibraryViewModel {
    public var inProgressEpisodes: [Episode] = []
    public var completedEpisodes: [Episode] = []
    public var downloadedEpisodes: [Episode] = []

    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func load() {
        let allEpisodes = (try? modelContext.fetch(FetchDescriptor<Episode>())) ?? []

        inProgressEpisodes = allEpisodes
            .filter { $0.episodeStatus == .inProgress }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }

        completedEpisodes = allEpisodes
            .filter { $0.episodeStatus == .completed }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }

        downloadedEpisodes = allEpisodes
            .filter { $0.isDownloaded }
    }
}
