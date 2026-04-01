import Testing
import Foundation
@testable import RadioPlayer

@Suite("Domain Models")
struct DomainModelTests {

    // MARK: - EpisodeStatus

    @Test("EpisodeStatus has all expected cases")
    func episodeStatusCases() {
        let allCases = EpisodeStatus.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.new))
        #expect(allCases.contains(.inProgress))
        #expect(allCases.contains(.completed))
        #expect(allCases.contains(.notListened))
    }

    @Test("EpisodeStatus raw values round-trip through JSON")
    func episodeStatusCodable() throws {
        for status in EpisodeStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(EpisodeStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    @Test("EpisodeStatus has display names")
    func episodeStatusDisplayName() {
        #expect(EpisodeStatus.new.displayName == "New")
        #expect(EpisodeStatus.inProgress.displayName == "In Progress")
        #expect(EpisodeStatus.completed.displayName == "Completed")
        #expect(EpisodeStatus.notListened.displayName == "Not Listened")
    }

    // MARK: - ArchiveCollection

    @Test("ArchiveCollection has correct raw values for API queries")
    func archiveCollectionRawValues() {
        #expect(ArchiveCollection.oldTimeRadio.rawValue == "oldtimeradio")
        #expect(ArchiveCollection.radioBooks.rawValue == "radiobooks")
    }

    @Test("ArchiveCollection has human-readable display names")
    func archiveCollectionDisplayNames() {
        #expect(ArchiveCollection.oldTimeRadio.displayName == "All Shows")
        #expect(ArchiveCollection.radioBooks.displayName == "Radio Books")
    }

    @Test("ArchiveCollection has SF Symbol names")
    func archiveCollectionSystemImages() {
        #expect(ArchiveCollection.oldTimeRadio.systemImage == "radio")
        #expect(ArchiveCollection.radioBooks.systemImage == "book.closed")
    }

    @Test("ArchiveCollection conforms to Identifiable")
    func archiveCollectionIdentifiable() {
        #expect(ArchiveCollection.oldTimeRadio.id == "oldtimeradio")
        #expect(ArchiveCollection.radioBooks.id == "radiobooks")
    }
}
