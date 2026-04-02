import Testing
import Foundation
import SwiftData
@testable import RadioPlayer

/// Verifies that episode titles produced by ShowDetailViewModel.loadEpisodes()
/// match the authoritative OTRR episode log for the first 50 available Dragnet episodes.
///
/// The expected titles come from https://otrr.org/FILES/Logs_txt/Dragnet.txt
/// Episodes are matched to log entries via broadcast date parsed from the filename.
@Suite("Dragnet title cleaning against OTRR log")
@MainActor
struct DragnetTitleCleaningTests {

    // MARK: - OTRR log: date (YY-MM-DD) → authoritative title

    private static let otrr: [String: String] = [
        "49-06-10": "Production 2 aka Homicide aka The Nickel Plated Gun",
        "49-06-17": "Production 3 aka The Werewolf",
        "49-06-24": "Production 4 aka Homicide aka Quick Trigger Gun Men",
        "49-07-07": "The Helen Corday Murder",
        "49-07-14": "Red Light Bandit",
        "49-07-21": "Attempted City Hall Bombing",
        "49-07-28": "Missing Persons - Juanita Lasky",
        "49-08-04": "Benny Trounsel - Narcotics",
        "49-08-11": "Production 10 aka Homicide aka Maniac Murderer aka Mad Killer At Large",
        "49-08-18": "Production 11 aka Sixteen Jewel Thieves",
        "49-08-25": "Police Academy - Mario Koski",
        "49-09-01": "Auto Burglaries - Myra, the Redhead",
        "49-09-03": "Eric Kelby - Body Buried In Nursery",
        "49-09-10": "Sullivan Kidnapping",
        "49-09-17": "James Vickers - Cop Killing - Tunnel Chase",
        "49-09-24": "Brick-Bat Slayer",
        "49-10-01": "Truck Hi-jackers - Tom Laval",
        "49-11-24": "Mrs. Rinard, Albert Barry - Mother-In-Law Murder",
        "49-12-01": "Spring Street Gang - Juveniles",
        "49-12-08": "George Quan - The Jade Thumb Rings",
        "49-12-22": "22 Rifle for Christmas",
        "49-12-29": "The Roseland Roof Murders",
        "50-01-05": "Max Tyler - Escaped Convict",
        "50-01-12": "The Big Man Part 1 (Narcotics)",
        "50-01-19": "The Big Man Part 2 (Narcotics)",
        "50-02-02": "Claude Jimmerson, Child Killer",
        "50-02-09": "The Big Girl",
        "50-02-23": "The Big Grifter",
        "50-03-02": "The Big Kill",
        "50-03-09": "The Big Thank You",
        "50-03-16": "The Big Boys",
        "50-03-23": "The Big Gangster Part 1",
        "50-03-30": "The Big Gangster Part 2",
        "50-04-06": "The Big Book",
        "50-04-13": "The Big Watch",
        "50-04-20": "The Big Trial",
        "50-04-27": "The Big Job",
        "50-05-04": "The Big Badge",
        "50-05-11": "The Big Knife",
        "50-05-18": "The Big Pug",
        "50-05-25": "The Big Key",
        "50-06-01": "The Big Fake",
        "50-06-08": "The Big Smart Guy",
        "50-06-15": "The Big Press",
        "50-06-22": "The Big Mink",
        "50-06-29": "The Big Grab",
        "50-07-06": "The Big Frame",
        "50-07-13": "The Big Bomb",
        "50-07-20": "The Big Gent Part 1",
        "50-07-27": "The Big Gent Part 2",
    ]

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

    /// Extract the two-digit date key (YY-MM-DD) from a Dragnet filename.
    private func dateKey(from filename: String) -> String? {
        let regex = #/(\d{2})-(\d{2})-(\d{2})/#
        guard let m = filename.firstMatch(of: regex) else { return nil }
        return "\(m.1)-\(m.2)-\(m.3)"
    }

    // MARK: - Tests

    @Test("all 50 real Dragnet episodes clean to OTRR log title")
    func allEpisodesMatchOTRRLog() async throws {
        let data = try loadFixture("item_metadata_dragnet_real")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles",
                        title: "Dragnet - Single Episodes",
                        collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        var failures: [String] = []

        for episode in vm.episodes {
            guard let key = dateKey(from: episode.filename),
                  let expected = Self.otrr[key] else { continue }

            let got = episode.title ?? episode.filename
            if got != expected {
                failures.append("[\(key)] expected \(expected.debugDescription), got \(got.debugDescription)")
            }
        }

        #expect(failures.isEmpty, "Title mismatches:\n\(failures.joined(separator: "\n"))")
    }

    /// Spot-check: dirty title with episode number embedded after date.
    @Test("dirty archive title (ep013) cleans to OTRR title")
    func dirtyTitleEp013() async throws {
        let data = try loadFixture("item_metadata_dragnet_real")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles",
                        title: "Dragnet - Single Episodes",
                        collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        let ep = vm.episodes.first { $0.filename.contains("49-09-01") }
        #expect(ep?.title == "Auto Burglaries - Myra, the Redhead")
    }

    /// Spot-check: title starting with a number must NOT have that number stripped.
    @Test("title starting with number (22 Rifle for Christmas) is not truncated")
    func titleStartingWithNumberNotStripped() async throws {
        let data = try loadFixture("item_metadata_dragnet_real")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let container = try makeContainer()
        let context = ModelContext(container)

        let show = Show(identifier: "OTRR_Dragnet_Singles",
                        title: "Dragnet - Single Episodes",
                        collection: "oldtimeradio")
        context.insert(show)
        try context.save()

        let vm = ShowDetailViewModel(show: show, api: api, modelContext: context)
        await vm.loadEpisodes()

        let ep = vm.episodes.first { $0.filename.contains("49-12-22") }
        #expect(ep?.title == "22 Rifle for Christmas")
    }
}
