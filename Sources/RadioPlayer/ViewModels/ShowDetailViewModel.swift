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

            // Deduplicate: group by canonical key, prefer MP3 within each group
            let grouped = Dictionary(grouping: audioFiles) { canonicalKey(for: $0, showTitle: show.title) }
            let deduped = grouped.values.compactMap { group -> ArchiveFile? in
                group.first(where: { $0.format?.lowercased().contains("mp3") == true }) ?? group.first
            }

            let existingByFilename = Dictionary(
                uniqueKeysWithValues: show.episodes.map { ($0.filename, $0) }
            )

            var result: [Episode] = []

            for file in deduped {
                let cleanTitle = cleanedTitle(for: file, showTitle: show.title)
                if let existing = existingByFilename[file.name] {
                    // Update metadata but preserve user state
                    existing.title = cleanTitle
                    existing.track = file.track ?? existing.track
                    existing.duration = file.length.flatMap(Double.init) ?? existing.duration
                    existing.fileSize = file.size.flatMap(Int64.init) ?? existing.fileSize
                    result.append(existing)
                } else {
                    let episode = Episode(filename: file.name, format: file.format ?? "Unknown")
                    episode.title = cleanTitle
                    episode.track = file.track
                    episode.duration = file.length.flatMap(Double.init)
                    episode.fileSize = file.size.flatMap(Int64.init)
                    show.episodes.append(episode)
                    result.append(episode)
                }
            }

            // Sort by track number, then cleaned title, then filename
            result.sort { lhs, rhs in
                if let lt = lhs.track, let rt = rhs.track, lt != rt {
                    return lt.localizedStandardCompare(rt) == .orderedAscending
                }
                let lt = lhs.title ?? lhs.filename
                let rt = rhs.title ?? rhs.filename
                return lt.localizedStandardCompare(rt) == .orderedAscending
            }

            try modelContext.save()
            episodes = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private helpers

    /// Normalized key for grouping duplicate files (same episode, different formats).
    private func canonicalKey(for file: ArchiveFile, showTitle: String) -> String {
        if let title = file.title, !title.isEmpty {
            return title.lowercased().trimmingCharacters(in: .whitespaces)
        }
        var name = (file.name as NSString).deletingPathExtension.lowercased()
        name = name.replacingOccurrences(of: "_", with: " ")
        // Strip leading track number: "01 ", "1 ", etc.
        name = name.replacing(#/^\d+\s+/#, with: "")
        // Strip show name prefix — try the short name (before " - ") first, then full title
        stripShowPrefix(from: &name, showTitle: showTitle.lowercased())
        // Strip date prefix: YY-MM-DD or YYYY-MM-DD
        name = name.replacing(#/^\d{2,4}-\d{2}-\d{2}\s*/#, with: "")
        return name.trimmingCharacters(in: .init(charactersIn: " _-"))
    }

    /// Human-readable title: uses explicit title field or cleans the filename.
    private func cleanedTitle(for file: ArchiveFile, showTitle: String) -> String {
        if let title = file.title, !title.isEmpty { return title }
        var name = (file.name as NSString).deletingPathExtension
        name = name.replacingOccurrences(of: "_", with: " ")
        // Strip leading track number
        name = name.replacing(#/^\d+\s+/#, with: "")
        // Strip show name prefix (case-insensitive)
        var lower = name.lowercased()
        stripShowPrefix(from: &lower, showTitle: showTitle.lowercased())
        if lower.count < name.count {
            name = String(name.suffix(lower.count))
        }
        // Strip date prefix
        name = name.replacing(#/^\d{2,4}-\d{2}-\d{2}\s*/#, with: "")
        let cleaned = name.trimmingCharacters(in: .init(charactersIn: " _-"))
        return cleaned.isEmpty ? file.name : cleaned
    }

    /// Strips a show name prefix from `name` in place. Tries the short name
    /// (the part before " - ") first so "Abbott and Costello - Single Episodes"
    /// also matches filenames prefixed with just "Abbott and Costello".
    private func stripShowPrefix(from name: inout String, showTitle: String) {
        let candidates = [
            showTitle.components(separatedBy: " - ").first ?? showTitle,
            showTitle
        ]
        for candidate in candidates {
            let prefix = candidate + " "
            if name.hasPrefix(prefix) {
                name = String(name.dropFirst(prefix.count))
                return
            }
        }
    }
}
