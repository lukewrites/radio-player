import Testing
import Foundation
@testable import RadioPlayer

@Suite("Archive.org API Model Decoding")
struct APIModelsTests {

    private func loadFixture(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw TestError.fixtureNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    @Test("Decode search response with numFound, start, and docs")
    func decodeSearchResponse() throws {
        let data = try loadFixture("search_response")
        let response = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)

        #expect(response.response.numFound == 8855)
        #expect(response.response.start == 0)
        #expect(response.response.docs.count == 2)
    }

    @Test("Decode search doc with string creator")
    func decodeSearchDocStringCreator() throws {
        let data = try loadFixture("search_response")
        let response = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
        let doc = response.response.docs[0]

        #expect(doc.identifier == "OTRR_Dragnet_Singles")
        #expect(doc.title == "Dragnet: Big Crime")
        #expect(doc.description == "The story of a Los Angeles police detective and his partners.")
        #expect(doc.creator == ["NBC Radio"])
        #expect(doc.date == "1949-09-17T00:00:00Z")
        #expect(doc.downloads == 54321)
    }

    @Test("Decode search doc with array creator")
    func decodeSearchDocArrayCreator() throws {
        let data = try loadFixture("search_response")
        let response = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
        let doc = response.response.docs[1]

        #expect(doc.identifier == "OTRR_Suspense_Singles")
        #expect(doc.creator == ["CBS Radio", "AutoProgrammed"])
    }
}

enum TestError: Error {
    case fixtureNotFound(String)
}
