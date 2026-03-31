import Foundation
import Observation

@Observable
@MainActor
public final class CollectionBrowserViewModel {
    public var shows: [SearchDoc] = []
    public var isLoading = false
    public var searchText = ""
    public var totalCount = 0
    public var errorMessage: String?

    public var hasMore: Bool { shows.count < totalCount }

    private let collection: ArchiveCollection
    private let api: ArchiveAPI
    private let pageSize: Int
    private var currentStart = 0

    public init(collection: ArchiveCollection, api: ArchiveAPI, pageSize: Int = 40) {
        self.collection = collection
        self.api = api
        self.pageSize = pageSize
    }

    public func loadInitial() async {
        currentStart = 0
        shows = []
        errorMessage = nil
        isLoading = true

        do {
            let result = try await api.searchCollection(
                collection,
                query: searchText.isEmpty ? nil : searchText,
                start: 0,
                rows: pageSize
            )
            shows = result.docs
            totalCount = result.totalCount
            currentStart = result.docs.count
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true

        do {
            let result = try await api.searchCollection(
                collection,
                query: searchText.isEmpty ? nil : searchText,
                start: currentStart,
                rows: pageSize
            )
            shows.append(contentsOf: result.docs)
            totalCount = result.totalCount
            currentStart += result.docs.count
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func search(_ query: String) async {
        searchText = query
        await loadInitial()
    }
}
