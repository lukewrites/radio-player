import Testing
import Foundation
import SwiftData
@testable import RadioPlayer

@Suite("LibraryViewModel")
@MainActor
struct LibraryViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Show.self, Episode.self, configurations: config)
    }

    private func seedData(context: ModelContext) throws {
        let show1 = Show(identifier: "dragnet", title: "Dragnet", collection: "oldtimeradio")
        let show2 = Show(identifier: "shadow", title: "The Shadow", collection: "oldtimeradio")

        let ep1 = Episode(filename: "ep1.mp3", format: "MP3")
        ep1.episodeStatus = .inProgress
        ep1.playbackPosition = 300
        ep1.duration = 1800
        ep1.lastPlayedAt = Date()

        let ep2 = Episode(filename: "ep2.mp3", format: "MP3")
        ep2.episodeStatus = .completed
        ep2.duration = 1800
        ep2.lastPlayedAt = Date().addingTimeInterval(-3600)

        let ep3 = Episode(filename: "ep3.mp3", format: "MP3")
        ep3.episodeStatus = .inProgress
        ep3.isDownloaded = true
        ep3.localFilePath = "Downloads/shadow/ep3.mp3"
        ep3.duration = 900
        ep3.lastPlayedAt = Date().addingTimeInterval(-7200)

        let ep4 = Episode(filename: "ep4.mp3", format: "MP3")
        ep4.episodeStatus = .new
        ep4.isDownloaded = true
        ep4.localFilePath = "Downloads/shadow/ep4.mp3"

        show1.episodes.append(ep1)
        show1.episodes.append(ep2)
        show2.episodes.append(ep3)
        show2.episodes.append(ep4)

        context.insert(show1)
        context.insert(show2)
        try context.save()
    }

    // MARK: - In Progress

    @Test("inProgressEpisodes returns episodes with inProgress status")
    func inProgressEpisodes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seedData(context: context)

        let vm = LibraryViewModel(modelContext: context)
        vm.load()

        #expect(vm.inProgressEpisodes.count == 2)
        #expect(vm.inProgressEpisodes.allSatisfy { $0.episodeStatus == .inProgress })
    }

    @Test("inProgressEpisodes are sorted by lastPlayedAt descending")
    func inProgressSortedByDate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seedData(context: context)

        let vm = LibraryViewModel(modelContext: context)
        vm.load()

        let dates = vm.inProgressEpisodes.compactMap { $0.lastPlayedAt }
        #expect(zip(dates, dates.dropFirst()).allSatisfy { $0 >= $1 })
    }

    // MARK: - Completed

    @Test("completedEpisodes returns episodes with completed status")
    func completedEpisodes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seedData(context: context)

        let vm = LibraryViewModel(modelContext: context)
        vm.load()

        #expect(vm.completedEpisodes.count == 1)
        #expect(vm.completedEpisodes[0].filename == "ep2.mp3")
    }

    // MARK: - Downloads

    @Test("downloadedEpisodes returns episodes where isDownloaded is true")
    func downloadedEpisodes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seedData(context: context)

        let vm = LibraryViewModel(modelContext: context)
        vm.load()

        #expect(vm.downloadedEpisodes.count == 2)
        #expect(vm.downloadedEpisodes.allSatisfy { $0.isDownloaded })
    }

    // MARK: - Empty state

    @Test("returns empty arrays when no data exists")
    func emptyLibrary() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let vm = LibraryViewModel(modelContext: context)
        vm.load()

        #expect(vm.inProgressEpisodes.isEmpty)
        #expect(vm.completedEpisodes.isEmpty)
        #expect(vm.downloadedEpisodes.isEmpty)
    }
}
