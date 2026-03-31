import Testing
import Foundation
import SwiftData
@testable import RadioPlayer

@Suite("AudioPlayerService")
@MainActor
struct AudioPlayerServiceTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Show.self, Episode.self, configurations: config)
    }

    private func makeShowAndEpisode(context: ModelContext) throws -> (Show, Episode) {
        let show = Show(identifier: "test_show", title: "Test Show", collection: "oldtimeradio")
        let episode = Episode(filename: "episode1.mp3", format: "VBR MP3")
        episode.duration = 1800
        show.episodes.append(episode)
        context.insert(show)
        try context.save()
        return (show, episode)
    }

    // MARK: - Initial State

    @Test("Service starts with no episode and not playing")
    func initialState() {
        let service = AudioPlayerService()
        #expect(service.currentEpisode == nil)
        #expect(service.isPlaying == false)
        #expect(service.currentTime == 0)
        #expect(service.duration == 0)
        #expect(service.playbackRate == 1.0)
    }

    // MARK: - Episode Status Transitions

    @Test("Playing an episode sets status to inProgress")
    func playingSetsInProgress() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (_, episode) = try makeShowAndEpisode(context: context)

        #expect(episode.episodeStatus == .new)

        let service = AudioPlayerService()
        service.setCurrentEpisode(episode)

        #expect(episode.episodeStatus == .inProgress)
    }

    @Test("Episode marked completed when reaching 95% of duration")
    func completionAt95Percent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (_, episode) = try makeShowAndEpisode(context: context)
        episode.duration = 1000

        let service = AudioPlayerService()
        service.setCurrentEpisode(episode)
        service.updateProgress(currentTime: 960, duration: 1000)

        #expect(episode.episodeStatus == .completed)
    }

    @Test("Episode stays inProgress below 95%")
    func notCompletedBelow95() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (_, episode) = try makeShowAndEpisode(context: context)
        episode.duration = 1000

        let service = AudioPlayerService()
        service.setCurrentEpisode(episode)
        service.updateProgress(currentTime: 500, duration: 1000)

        #expect(episode.episodeStatus == .inProgress)
        #expect(episode.playbackPosition == 500)
    }

    // MARK: - Playback Position

    @Test("updateProgress saves position to episode")
    func progressSaved() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (_, episode) = try makeShowAndEpisode(context: context)

        let service = AudioPlayerService()
        service.setCurrentEpisode(episode)
        service.updateProgress(currentTime: 300.5, duration: 1800)

        #expect(episode.playbackPosition == 300.5)
        #expect(episode.lastPlayedAt != nil)
    }

    // MARK: - Playback Rate

    @Test("Playback rate can be changed")
    func playbackRate() {
        let service = AudioPlayerService()
        #expect(service.playbackRate == 1.0)

        service.playbackRate = 1.5
        #expect(service.playbackRate == 1.5)

        service.playbackRate = 2.0
        #expect(service.playbackRate == 2.0)
    }

    // MARK: - Queue

    @Test("Queue starts empty")
    func emptyQueue() {
        let service = AudioPlayerService()
        #expect(service.queue.isEmpty)
        #expect(service.queueIndex == 0)
    }

    @Test("setQueue populates queue and index")
    func setQueue() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "test_show", title: "Test Show", collection: "oldtimeradio")
        let ep1 = Episode(filename: "episode1.mp3", format: "MP3")
        ep1.duration = 1800
        let ep2 = Episode(filename: "episode2.mp3", format: "MP3")
        ep2.duration = 900
        context.insert(show)
        show.episodes.append(ep1)
        show.episodes.append(ep2)
        try context.save()

        // Use explicit array to control order (SwiftData relationship order is not guaranteed)
        let orderedEpisodes = [ep1, ep2]
        let service = AudioPlayerService()
        service.setQueue(orderedEpisodes, startingAt: 0)

        #expect(service.queue.count == 2)
        #expect(service.queueIndex == 0)
        #expect(service.currentEpisode?.filename == "episode1.mp3")
    }

    @Test("nextInQueue advances to next episode")
    func nextInQueue() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "test_show", title: "Test Show", collection: "oldtimeradio")
        let ep1 = Episode(filename: "episode1.mp3", format: "MP3")
        ep1.duration = 1800
        let ep2 = Episode(filename: "episode2.mp3", format: "MP3")
        ep2.duration = 900
        context.insert(show)
        show.episodes.append(ep1)
        show.episodes.append(ep2)
        try context.save()

        let orderedEpisodes = [ep1, ep2]
        let service = AudioPlayerService()
        service.setQueue(orderedEpisodes, startingAt: 0)

        let advanced = service.nextInQueue()
        #expect(advanced == true)
        #expect(service.queueIndex == 1)
        #expect(service.currentEpisode?.filename == "episode2.mp3")
    }

    @Test("nextInQueue returns false at end of queue")
    func nextInQueueAtEnd() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let (_, episode) = try makeShowAndEpisode(context: context)

        let service = AudioPlayerService()
        service.setQueue([episode], startingAt: 0)

        let advanced = service.nextInQueue()
        #expect(advanced == false)
        #expect(service.queueIndex == 0)
    }
}
