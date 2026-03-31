import Testing
import Foundation
import SwiftData
@testable import RadioPlayer

@Suite("Show and Episode SwiftData Models")
struct ShowModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Show.self, Episode.self, configurations: config)
    }

    // MARK: - Show

    @Test("Show can be created and persisted")
    func createShow() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let descriptor = FetchDescriptor<Show>()
        let shows = try context.fetch(descriptor)
        #expect(shows.count == 1)
        #expect(shows[0].identifier == "OTRR_Dragnet_Singles")
        #expect(shows[0].title == "Dragnet")
        #expect(shows[0].collection == "oldtimeradio")
    }

    @Test("Show defaults are correct")
    func showDefaults() {
        let show = Show(identifier: "test", title: "Test Show", collection: "oldtimeradio")
        #expect(show.isFavorite == false)
        #expect(show.downloads == 0)
        #expect(show.episodes.isEmpty)
    }

    @Test("Show thumbnailURL is constructed from identifier")
    func showThumbnailURL() {
        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        #expect(show.thumbnailImageURL?.absoluteString == "https://archive.org/services/img/OTRR_Dragnet_Singles")
    }

    // MARK: - Episode

    @Test("Episode can be created with defaults")
    func createEpisode() {
        let episode = Episode(filename: "Dragnet_49-09-17.mp3", format: "VBR MP3")
        #expect(episode.filename == "Dragnet_49-09-17.mp3")
        #expect(episode.format == "VBR MP3")
        #expect(episode.episodeStatus == .new)
        #expect(episode.playbackPosition == 0)
        #expect(episode.isDownloaded == false)
    }

    @Test("Episode status enum maps to/from stored string")
    func episodeStatusMapping() {
        let episode = Episode(filename: "test.mp3", format: "MP3")
        #expect(episode.episodeStatus == .new)

        episode.episodeStatus = .inProgress
        #expect(episode.status == "inProgress")

        episode.episodeStatus = .completed
        #expect(episode.status == "completed")
    }

    @Test("Episode streamURL is constructed from show identifier and filename")
    func episodeStreamURL() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        let episode = Episode(filename: "Dragnet_49-09-17.mp3", format: "VBR MP3")
        show.episodes.append(episode)
        context.insert(show)
        try context.save()

        #expect(episode.streamURL?.absoluteString == "https://archive.org/download/OTRR_Dragnet_Singles/Dragnet_49-09-17.mp3")
    }

    @Test("Episode without show has nil streamURL")
    func episodeNoShowStreamURL() {
        let episode = Episode(filename: "test.mp3", format: "MP3")
        #expect(episode.streamURL == nil)
    }

    // MARK: - Show-Episode Relationship

    @Test("Show cascades delete to episodes")
    func cascadeDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "test", title: "Test", collection: "oldtimeradio")
        let ep1 = Episode(filename: "ep1.mp3", format: "MP3")
        let ep2 = Episode(filename: "ep2.mp3", format: "MP3")
        show.episodes.append(ep1)
        show.episodes.append(ep2)
        context.insert(show)
        try context.save()

        context.delete(show)
        try context.save()

        let episodes = try context.fetch(FetchDescriptor<Episode>())
        #expect(episodes.isEmpty)
    }
}
