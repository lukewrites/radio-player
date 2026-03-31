import Testing
import Foundation
import SwiftData
@testable import RadioPlayer

@Suite("DownloadManager")
@MainActor
struct DownloadManagerTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Show.self, Episode.self, configurations: config)
    }

    private func makeEpisode(context: ModelContext, identifier: String = "test_show") throws -> Episode {
        let show = Show(identifier: identifier, title: "Test Show", collection: "oldtimeradio")
        let episode = Episode(filename: "episode1.mp3", format: "VBR MP3")
        show.episodes.append(episode)
        context.insert(show)
        try context.save()
        return episode
    }

    // MARK: - Local File Path

    @Test("localFilePath is constructed from show identifier and filename")
    func localFilePath() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        let path = manager.localFilePath(for: episode)
        #expect(path == "Downloads/test_show/episode1.mp3")
    }

    @Test("localFilePath returns nil when episode has no show")
    func localFilePathNoShow() {
        let manager = DownloadManager()
        let episode = Episode(filename: "episode1.mp3", format: "MP3")
        #expect(manager.localFilePath(for: episode) == nil)
    }

    // MARK: - Download State

    @Test("isDownloading returns false when episode not in active downloads")
    func isDownloadingFalse() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        #expect(manager.isDownloading(episode) == false)
    }

    @Test("progress returns nil for episode not being downloaded")
    func progressNil() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        #expect(manager.progress(for: episode) == nil)
    }

    // MARK: - Download Completion

    @Test("markDownloadComplete sets episode as downloaded with correct path")
    func markDownloadComplete() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        manager.markDownloadComplete(for: episode, context: context)

        #expect(episode.isDownloaded == true)
        #expect(episode.localFilePath == "Downloads/test_show/episode1.mp3")
    }

    @Test("markDownloadComplete removes episode from active downloads")
    func downloadCompleteRemovesActive() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        // Simulate an active download entry
        manager.simulateActiveDownload(for: episode)
        #expect(manager.isDownloading(episode) == true)

        manager.markDownloadComplete(for: episode, context: context)
        #expect(manager.isDownloading(episode) == false)
    }

    // MARK: - Delete Download

    @Test("deleteDownload clears episode download state")
    func deleteDownload() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        manager.markDownloadComplete(for: episode, context: context)
        #expect(episode.isDownloaded == true)

        manager.deleteDownload(for: episode, context: context)
        #expect(episode.isDownloaded == false)
        #expect(episode.localFilePath == nil)
    }

    // MARK: - Progress Tracking

    @Test("updateProgress stores fraction completed")
    func updateProgress() throws {
        let manager = DownloadManager()
        let container = try makeContainer()
        let context = ModelContext(container)
        let episode = try makeEpisode(context: context)

        manager.simulateActiveDownload(for: episode)
        manager.updateProgress(for: episode, bytesWritten: 500_000, totalBytes: 1_000_000)

        let progress = manager.progress(for: episode)
        #expect(progress?.fractionCompleted == 0.5)
        #expect(progress?.downloadedBytes == 500_000)
        #expect(progress?.totalBytes == 1_000_000)
    }
}
