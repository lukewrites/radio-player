import Testing
@testable import RadioPlayer

@Suite("ArchiveCollection")
struct ArchiveCollectionTests {

    @Test("allCases contains all 9 collections")
    func allCasesCount() {
        #expect(ArchiveCollection.allCases.count == 9)
    }

    @Test("each case has a non-empty displayName")
    func displayNames() {
        for collection in ArchiveCollection.allCases {
            #expect(!collection.displayName.isEmpty, "displayName empty for \(collection.id)")
        }
    }

    @Test("each case has a non-empty systemImage")
    func systemImages() {
        for collection in ArchiveCollection.allCases {
            #expect(!collection.systemImage.isEmpty, "systemImage empty for \(collection.id)")
        }
    }

    @Test("each case has a non-empty description")
    func descriptions() {
        for collection in ArchiveCollection.allCases {
            #expect(!collection.description.isEmpty, "description empty for \(collection.id)")
        }
    }

    @Test("each case has a non-empty baseQuery")
    func baseQueries() {
        for collection in ArchiveCollection.allCases {
            #expect(!collection.baseQuery.isEmpty, "baseQuery empty for \(collection.id)")
        }
    }

    @Test("oldTimeRadio uses OTRR identifier filter")
    func oldTimeRadioBaseQuery() {
        #expect(ArchiveCollection.oldTimeRadio.baseQuery == "identifier:OTRR_*")
    }

    @Test("radioBooks uses collection filter")
    func radioBooksBaseQuery() {
        #expect(ArchiveCollection.radioBooks.baseQuery == "collection:radiobooks")
    }

    @Test("OTRR genre cases are in otrr category")
    func otrrCategory() {
        let otrrCases: [ArchiveCollection] = [
            .oldTimeRadio, .otrrDrama, .otrrComedy, .otrrMystery,
            .otrrAdventure, .otrrWestern, .otrrScienceFiction, .otrrHorror
        ]
        for collection in otrrCases {
            #expect(collection.category == .otrr, "\(collection.id) should be .otrr category")
        }
    }

    @Test("radioBooks is in general category")
    func generalCategory() {
        #expect(ArchiveCollection.radioBooks.category == .general)
    }

    @Test("OTRR genre queries contain OTRR identifier filter")
    func otrrGenreQueriesContainFilter() {
        let genreCases: [ArchiveCollection] = [
            .otrrDrama, .otrrComedy, .otrrMystery,
            .otrrAdventure, .otrrWestern, .otrrScienceFiction, .otrrHorror
        ]
        for collection in genreCases {
            #expect(collection.baseQuery.contains("identifier:OTRR_*"),
                    "\(collection.id) baseQuery should include OTRR identifier filter")
        }
    }
}
