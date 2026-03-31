import Testing
import Foundation
import SwiftData
@testable import RadioPlayer

@Suite("ShowDetailViewModel")
@MainActor
struct ShowDetailViewModelTests {

    private func loadFixture(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw TestError.fixtureNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Show.self, Episode.self, configurations: config)
    }

    // MARK: - Episode Loading

    @Test("loadEpisodes fetches metadata and creates episodes")
    func loadEpisodes() async throws {
        let data = try loadFixture("item_metadata")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        // Should only have playable audio files (3 of 6 in fixture)
        #expect(vm.episodes.count == 3)
        #expect(vm.isLoading == false)
    }

    @Test("loadEpisodes populates episode fields from file metadata")
    func episodeFields() async throws {
        let data = try loadFixture("item_metadata")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        let mp3Episodes = vm.episodes.filter { $0.format.contains("MP3") }
        let firstMp3 = mp3Episodes.first { $0.filename == "Dragnet_49-09-17_Cop_Killing.mp3" }

        #expect(firstMp3 != nil)
        #expect(firstMp3?.title == "Cop Killing")
        #expect(firstMp3?.track == "01")
        #expect(firstMp3?.duration == 1802.5)
        #expect(firstMp3?.fileSize == 7654321)
    }

    @Test("loadEpisodes preserves existing episode status on reload")
    func upsertPreservesStatus() async throws {
        let data = try loadFixture("item_metadata")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)

        // Pre-existing episode with in-progress status
        let existing = Episode(filename: "Dragnet_49-09-17_Cop_Killing.mp3", format: "VBR MP3")
        existing.episodeStatus = .inProgress
        existing.playbackPosition = 450.0
        show.episodes.append(existing)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        let reloaded = vm.episodes.first { $0.filename == "Dragnet_49-09-17_Cop_Killing.mp3" }
        #expect(reloaded?.episodeStatus == .inProgress)
        #expect(reloaded?.playbackPosition == 450.0)
    }

    @Test("loadEpisodes associates episodes with show")
    func episodesLinkedToShow() async throws {
        let data = try loadFixture("item_metadata")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        #expect(vm.episodes.allSatisfy { $0.show?.identifier == "OTRR_Dragnet_Singles" })
    }

    // MARK: - Error Handling

    @Test("loadEpisodes sets error on network failure")
    func loadEpisodesError() async throws {
        let api = ArchiveAPI(session: FailingMockURLSession())
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "test", title: "Test", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        #expect(vm.episodes.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Filtering

    @Test("filteredEpisodes returns all when no filter set")
    func noFilter() async throws {
        let data = try loadFixture("item_metadata")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        #expect(vm.filteredEpisodes.count == vm.episodes.count)
    }

    @Test("filteredEpisodes filters by status")
    func filterByStatus() async throws {
        let data = try loadFixture("item_metadata")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles", title: "Dragnet", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        // Mark one as completed
        vm.episodes[0].episodeStatus = .completed

        vm.filterStatus = .completed
        #expect(vm.filteredEpisodes.count == 1)

        vm.filterStatus = .new
        #expect(vm.filteredEpisodes.count == 2)
    }
}
