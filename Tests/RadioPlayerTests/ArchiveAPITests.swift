import Testing
import Foundation
@testable import RadioPlayer

@Suite("ArchiveAPI")
struct ArchiveAPITests {

    private func loadFixture(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw TestError.fixtureNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    // MARK: - URL Construction

    @Test("Search URL includes collection, pagination, and field selection")
    func searchURLConstruction() throws {
        let api = ArchiveAPI()
        let url = api.searchURL(
            collection: .oldTimeRadio,
            query: nil,
            sortField: "downloads",
            sortDirection: "desc",
            start: 0,
            rows: 40
        )

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []

        #expect(components.host == "archive.org")
        #expect(components.path == "/advancedsearch.php")
        #expect(queryItems.contains { $0.name == "q" && $0.value == "identifier:OTRR_*" })
        #expect(queryItems.contains { $0.name == "output" && $0.value == "json" })
        #expect(queryItems.contains { $0.name == "rows" && $0.value == "40" })
        #expect(queryItems.contains { $0.name == "start" && $0.value == "0" })
        #expect(queryItems.contains { $0.name == "fl" && ($0.value?.contains("identifier") ?? false) })
        #expect(queryItems.contains { $0.name == "sort[]" && $0.value == "downloads desc" })
    }

    @Test("Search URL appends user query with AND")
    func searchURLWithQuery() throws {
        let api = ArchiveAPI()
        let url = api.searchURL(
            collection: .oldTimeRadio,
            query: "dragnet",
            sortField: "downloads",
            sortDirection: "desc",
            start: 0,
            rows: 40
        )

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let qParam = components.queryItems?.first { $0.name == "q" }?.value
        #expect(qParam == "identifier:OTRR_* AND (dragnet)")
    }

    @Test("Search URL paginates with start offset")
    func searchURLPagination() throws {
        let api = ArchiveAPI()
        let url = api.searchURL(
            collection: .radioBooks,
            query: nil,
            sortField: "title",
            sortDirection: "asc",
            start: 80,
            rows: 20
        )

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        #expect(queryItems.contains { $0.name == "start" && $0.value == "80" })
        #expect(queryItems.contains { $0.name == "rows" && $0.value == "20" })
        #expect(queryItems.contains { $0.name == "sort[]" && $0.value == "title asc" })
    }

    @Test("Metadata URL points to correct endpoint")
    func metadataURLConstruction() {
        let api = ArchiveAPI()
        let url = api.metadataURL(for: "OTRR_Dragnet_Singles")
        #expect(url.absoluteString == "https://archive.org/metadata/OTRR_Dragnet_Singles")
    }

    @Test("Thumbnail URL uses services/img endpoint")
    func thumbnailURLConstruction() {
        let api = ArchiveAPI()
        let url = api.thumbnailURL(for: "OTRR_Dragnet_Singles")
        #expect(url.absoluteString == "https://archive.org/services/img/OTRR_Dragnet_Singles")
    }

    @Test("Audio URL uses download endpoint")
    func audioURLConstruction() {
        let api = ArchiveAPI()
        let url = api.audioURL(identifier: "OTRR_Dragnet_Singles", filename: "Dragnet_49-09-17.mp3")
        #expect(url.absoluteString == "https://archive.org/download/OTRR_Dragnet_Singles/Dragnet_49-09-17.mp3")
    }

    // MARK: - Response Parsing

    @Test("searchCollection parses fixture data correctly")
    func searchCollectionParsing() async throws {
        let fixtureData = try loadFixture("search_response")
        let mockSession = MockURLSession(data: fixtureData)
        let api = ArchiveAPI(session: mockSession)

        let result = try await api.searchCollection(.oldTimeRadio)
        #expect(result.totalCount == 8855)
        #expect(result.docs.count == 2)
        #expect(result.docs[0].identifier == "OTRR_Dragnet_Singles")
    }

    @Test("fetchItemMetadata parses fixture data correctly")
    func fetchItemMetadataParsing() async throws {
        let fixtureData = try loadFixture("item_metadata")
        let mockSession = MockURLSession(data: fixtureData)
        let api = ArchiveAPI(session: mockSession)

        let metadata = try await api.fetchItemMetadata("OTRR_Dragnet_Singles")
        #expect(metadata.metadata?.title == "Dragnet: Big Crime")
        #expect(metadata.files.count == 6)
    }
}

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    let data: Data
    let response: URLResponse

    init(data: Data, statusCode: Int = 200) {
        self.data = data
        self.response = HTTPURLResponse(
            url: URL(string: "https://archive.org")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        (data, response)
    }
}
