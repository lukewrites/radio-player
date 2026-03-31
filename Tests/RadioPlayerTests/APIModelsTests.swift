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

    // MARK: - Item Metadata

    @Test("Decode item metadata with files list")
    func decodeItemMetadata() throws {
        let data = try loadFixture("item_metadata")
        let metadata = try JSONDecoder().decode(ArchiveItemMetadata.self, from: data)

        #expect(metadata.metadata?.identifier == "OTRR_Dragnet_Singles")
        #expect(metadata.metadata?.title == "Dragnet: Big Crime")
        #expect(metadata.files.count == 6)
    }

    @Test("Filter playable audio files from item metadata")
    func filterPlayableAudioFiles() throws {
        let data = try loadFixture("item_metadata")
        let metadata = try JSONDecoder().decode(ArchiveItemMetadata.self, from: data)
        let playable = metadata.files.filter(\.isPlayableAudio)

        #expect(playable.count == 3)
        #expect(playable.allSatisfy { $0.format?.lowercased().contains("mp3") == true || $0.format?.lowercased().contains("vorbis") == true })
    }

    @Test("Decode audio file metadata fields")
    func decodeAudioFileFields() throws {
        let data = try loadFixture("item_metadata")
        let metadata = try JSONDecoder().decode(ArchiveItemMetadata.self, from: data)
        let file = metadata.files[0]

        #expect(file.name == "Dragnet_49-09-17_Cop_Killing.mp3")
        #expect(file.source == "original")
        #expect(file.format == "VBR MP3")
        #expect(file.size == "7654321")
        #expect(file.length == "1802.5")
        #expect(file.title == "Cop Killing")
        #expect(file.track == "01")
    }

    @Test("Item metadata subject can be string or array")
    func decodeItemMetadataSubject() throws {
        let data = try loadFixture("item_metadata")
        let metadata = try JSONDecoder().decode(ArchiveItemMetadata.self, from: data)

        #expect(metadata.metadata?.subject == ["Old Time Radio", "Drama", "Crime"])
    }
}

enum TestError: Error {
    case fixtureNotFound(String)
}
