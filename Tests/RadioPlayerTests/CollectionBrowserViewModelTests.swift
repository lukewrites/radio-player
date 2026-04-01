import Testing
import Foundation
@testable import RadioPlayer

@Suite("CollectionBrowserViewModel")
@MainActor
struct CollectionBrowserViewModelTests {

    private func loadFixture(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw TestError.fixtureNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    // MARK: - Initial Load

    @Test("loadInitial populates shows and totalCount")
    func loadInitial() async throws {
        let data = try loadFixture("search_response")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        await vm.loadInitial()

        #expect(vm.shows.count == 2)
        #expect(vm.totalCount == 8855)
        #expect(vm.shows[0].identifier == "OTRR_Dragnet_Singles")
        #expect(vm.isLoading == false)
    }

    @Test("loadInitial resets state before loading")
    func loadInitialResets() async throws {
        let data = try loadFixture("search_response")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        // Load once
        await vm.loadInitial()
        #expect(vm.shows.count == 2)

        // Load again — should reset, not append
        await vm.loadInitial()
        #expect(vm.shows.count == 2)
    }

    // MARK: - Pagination

    @Test("hasMore is true when shows < totalCount")
    func hasMore() async throws {
        let data = try loadFixture("search_response")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        await vm.loadInitial()
        #expect(vm.hasMore == true)
    }

    @Test("loadMore appends next page of results")
    func loadMore() async throws {
        let page1 = try loadFixture("search_response")
        let page2 = try loadFixture("search_response_page2")
        let session = SequentialMockURLSession(responses: [page1, page2])
        let api = ArchiveAPI(session: session)
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api, pageSize: 2)

        await vm.loadInitial()
        #expect(vm.shows.count == 2)

        await vm.loadMore()
        #expect(vm.shows.count == 4)
        #expect(vm.shows[2].identifier == "OTRR_TheShadow_Singles")
        #expect(vm.shows[3].identifier == "OTRR_InnerSanctum_Singles")
    }

    @Test("loadMore does nothing when already loading")
    func loadMoreWhileLoading() async throws {
        let data = try loadFixture("search_response")
        let api = ArchiveAPI(session: MockURLSession(data: data))
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        await vm.loadInitial()
        vm.isLoading = true
        await vm.loadMore()
        // Should still only have original results since loadMore bailed out
        #expect(vm.shows.count == 2)
    }

    // MARK: - Search

    @Test("search updates query and reloads")
    func search() async throws {
        let data = try loadFixture("search_response")
        let trackingSession = TrackingMockURLSession(data: data)
        let api = ArchiveAPI(session: trackingSession)
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        await vm.search("dragnet")

        #expect(vm.searchText == "dragnet")
        #expect(vm.shows.count == 2)
        // Verify the query was included in the URL
        let lastURL = trackingSession.lastRequestedURL
        #expect(lastURL?.absoluteString.contains("dragnet") == true)
    }

    // MARK: - Error Handling

    @Test("loadInitial sets error message on failure")
    func loadInitialError() async throws {
        let api = ArchiveAPI(session: FailingMockURLSession())
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        await vm.loadInitial()

        #expect(vm.shows.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @Test("loadInitial does not set errorMessage on cancellation")
    func loadInitialCancellationSilenced() async throws {
        let api = ArchiveAPI(session: CancellingMockURLSession())
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)

        await vm.loadInitial()

        #expect(vm.shows.isEmpty)
        #expect(vm.errorMessage == nil, "CancellationError should not surface as a user-visible error")
        #expect(vm.isLoading == false)
    }

    @Test("loadMore does not set errorMessage on cancellation")
    func loadMoreCancellationSilenced() async throws {
        let data = try loadFixture("search_response")
        let api = ArchiveAPI(session: SequentialMockURLSession(responses: [data]))
        let vm = CollectionBrowserViewModel(collection: .oldTimeRadio, api: api)
        await vm.loadInitial()

        let cancelApi = ArchiveAPI(session: CancellingMockURLSession())
        let vm2 = CollectionBrowserViewModel(collection: .oldTimeRadio, api: cancelApi)
        vm2.shows = vm.shows
        await vm2.loadMore()

        #expect(vm2.errorMessage == nil, "CancellationError should not surface as a user-visible error")
    }
}

// MARK: - Test Helpers

/// Returns different responses for sequential requests
final class SequentialMockURLSession: URLSessionProtocol, @unchecked Sendable {
    private var responses: [Data]
    private var index = 0

    init(responses: [Data]) {
        self.responses = responses
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let data = responses[min(index, responses.count - 1)]
        index += 1
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

/// Tracks the last requested URL
final class TrackingMockURLSession: URLSessionProtocol, @unchecked Sendable {
    private let responseData: Data
    var lastRequestedURL: URL?

    init(data: Data) {
        self.responseData = data
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        lastRequestedURL = url
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}

/// Always throws an error
final class FailingMockURLSession: URLSessionProtocol, @unchecked Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}

/// Throws CancellationError to simulate a task being cancelled mid-flight
final class CancellingMockURLSession: URLSessionProtocol, @unchecked Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        throw CancellationError()
    }
}
