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
    private let dateResolver: BroadcastDateResolver

    public init(show: Show, api: ArchiveAPI, modelContext: ModelContext,
                dateResolver: BroadcastDateResolver = (try? .fromBundle()) ?? .init()) {
        self.show = show
        self.api = api
        self.modelContext = modelContext
        self.dateResolver = dateResolver
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
                let resolved = dateResolver.resolve(filename: file.name, showIdentifier: show.identifier)
                if let existing = existingByFilename[file.name] {
                    // Update metadata but preserve user state
                    existing.title = cleanTitle
                    existing.track = file.track ?? existing.track
                    existing.duration = file.length.flatMap(Double.init) ?? existing.duration
                    existing.fileSize = file.size.flatMap(Int64.init) ?? existing.fileSize
                    // Don't overwrite a broadcastDate that was already set
                    if existing.broadcastDate == nil {
                        existing.broadcastDate = resolved
                    }
                    result.append(existing)
                } else {
                    let episode = Episode(filename: file.name, format: file.format ?? "Unknown")
                    episode.title = cleanTitle
                    episode.track = file.track
                    episode.duration = file.length.flatMap(Double.init)
                    episode.fileSize = file.size.flatMap(Int64.init)
                    episode.broadcastDate = resolved
                    show.episodes.append(episode)
                    result.append(episode)
                }
            }

            // Sort by broadcastDate (ascending) when available, then track, then title
            result.sort { lhs, rhs in
                switch (lhs.broadcastDate, rhs.broadcastDate) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    if let lt = lhs.track, let rt = rhs.track, lt != rt {
                        return lt.localizedStandardCompare(rt) == .orderedAscending
                    }
                    let lt = lhs.title ?? lhs.filename
                    let rt = rhs.title ?? rhs.filename
                    return lt.localizedStandardCompare(rt) == .orderedAscending
                }
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
    /// In both cases, strips any embedded date prefix (e.g. "JB 1943-10-10 ").
    private func cleanedTitle(for file: ArchiveFile, showTitle: String) -> String {
        var name = file.title?.isEmpty == false
            ? file.title!
            : (file.name as NSString).deletingPathExtension.replacingOccurrences(of: "_", with: " ")

        // Strip everything up to and including a date (YY-MM-DD / YYYY-MM-DD),
        // plus any optional episode marker like (xxx) that follows.
        // e.g. "JB 1943-10-10 Casablanca" → "Casablanca"
        // e.g. "Halls of Ivy 49-06-22 (xxx) Title" → "Title"
        let afterDate = name.replacing(#/^.*?\d{2,4}-\d{2}-\d{2}\s*(?:\(\w+\)\s*)?/#, with: "")
        if !afterDate.isEmpty, afterDate != name {
            name = afterDate
        } else {
            // No date found — strip leading track number and show name prefix
            name = name.replacing(#/^\d+\s+/#, with: "")
            var lower = name.lowercased()
            stripShowPrefix(from: &lower, showTitle: showTitle.lowercased())
            if lower.count < name.count {
                name = String(name.suffix(lower.count))
            }
        }

        let cleaned = name.trimmingCharacters(in: .init(charactersIn: " _-"))
        return cleaned.isEmpty ? (file.title ?? file.name) : cleaned
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
