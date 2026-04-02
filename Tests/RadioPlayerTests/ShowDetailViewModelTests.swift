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

        // 3 audio files in fixture, but Cop Killing has MP3+OGG → deduped to 2 episodes
        #expect(vm.episodes.count == 2)
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

    // MARK: - Deduplication
    // Fixtures use real archive.org data patterns from OTRR_Abbott_Costello_Singles
    // and OTRR_Jack_Benny_Singles_1943-1944.

    @Test("deduplicates MP3 and OGG sharing the same base filename")
    func deduplicatesMp3AndOgg() async throws {
        // Real pattern: "Abbott and Costello 40-07-31 Guest - Madame Lazonga.mp3"
        // + "Abbott and Costello 40-07-31 Guest - Madame Lazonga.ogg" — same stem
        let data = try loadFixture("item_metadata_dedup")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Abbott_Costello_Singles", title: "Abbott and Costello - Single Episodes", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        // 6 audio files (3 MP3 + 3 OGG) → 3 unique episodes after dedup
        #expect(vm.episodes.count == 3)
        // No OGG should remain when a matching MP3 exists
        #expect(!vm.episodes.contains { $0.format.lowercased().contains("ogg") },
                "OGG should be dropped when an MP3 exists with the same base filename")
    }

    @Test("uses clean title field when present (Abbott and Costello pattern)")
    func usesCleanTitleField() async throws {
        let data = try loadFixture("item_metadata_dedup")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Abbott_Costello_Singles", title: "Abbott and Costello - Single Episodes", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        // MP3 has title="Guest - Madame Lazonga" — should appear exactly as-is
        #expect(vm.episodes.contains { $0.title == "Guest - Madame Lazonga" },
                "Clean title field should be used unchanged")
        #expect(vm.episodes.contains { $0.title == "Bank Robbery with Marlene Dietrich" },
                "Clean title field should be used unchanged")
    }

    @Test("strips show name and track number from filename when no title field")
    func stripsShowNameAndTrackFromFilename() async throws {
        // Real pattern: "01 Abbott and Costello Audio Bio.mp3" has no title field
        let data = try loadFixture("item_metadata_dedup")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Abbott_Costello_Singles", title: "Abbott and Costello - Single Episodes", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        // "01 Abbott and Costello Audio Bio.mp3" → strip "01 " → strip show name → "Audio Bio"
        #expect(vm.episodes.contains { $0.title == "Audio Bio" },
                "Track number and show name should be stripped from filename-derived title")
    }

    @Test("strips date prefix from dirty title field (Jack Benny pattern)")
    func stripsDateFromDirtyTitleField() async throws {
        // Real pattern: title="JB 1943-10-10 Jack's African trip 1st Show of Season"
        // The title field itself contains show abbreviation + date prefix
        let data = try loadFixture("item_metadata_jackbenny")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Jack_Benny_Singles_1943-1944", title: "Jack Benny - Single Episodes - 1943-1944", collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        // 6 audio files (3 MP3 + 3 OGG) → 3 unique episodes
        #expect(vm.episodes.count == 3)
        // "JB 1943-10-10 Jack's African trip..." → "Jack's African trip 1st Show of Season"
        #expect(vm.episodes.contains { $0.title == "Jack's African trip 1st Show of Season" },
                "Date prefix in title field should be stripped")
        #expect(vm.episodes.contains { $0.title == "Casablanca" })
        #expect(vm.episodes.contains { $0.title == "Algiers" })
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
        #expect(vm.filteredEpisodes.count == 1)
    }
}
