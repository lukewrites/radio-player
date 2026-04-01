import Foundation
import Observation

public protocol URLSessionProtocol: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

@Observable
public final class ArchiveAPI: @unchecked Sendable {
    @ObservationIgnored private let session: URLSessionProtocol
    @ObservationIgnored private let baseURL = "https://archive.org"

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    // MARK: - URL Construction

    public func searchURL(
        collection: ArchiveCollection,
        query: String? = nil,
        sortField: String = "downloads",
        sortDirection: String = "desc",
        start: Int = 0,
        rows: Int = 40
    ) -> URL {
        var q = collection.baseQuery
        if let query, !query.isEmpty {
            q += " AND (\(query))"
        }

        var components = URLComponents(string: "\(baseURL)/advancedsearch.php")!
        components.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "output", value: "json"),
            URLQueryItem(name: "rows", value: "\(rows)"),
            URLQueryItem(name: "start", value: "\(start)"),
            URLQueryItem(name: "fl", value: "identifier,title,description,creator,date,downloads"),
            URLQueryItem(name: "sort[]", value: "\(sortField) \(sortDirection)")
        ]

        return components.url!
    }

    public func metadataURL(for identifier: String) -> URL {
        URL(string: "\(baseURL)/metadata/\(identifier)")!
    }

    public func thumbnailURL(for identifier: String) -> URL {
        URL(string: "\(baseURL)/services/img/\(identifier)")!
    }

    public func audioURL(identifier: String, filename: String) -> URL {
        URL(string: "\(baseURL)/download/\(identifier)/\(filename)")!
    }

    // MARK: - Network Requests

    public struct SearchResult: Sendable {
        public let docs: [SearchDoc]
        public let totalCount: Int
    }

    public func searchCollection(
        _ collection: ArchiveCollection,
        query: String? = nil,
        sortField: String = "downloads",
        sortDirection: String = "desc",
        start: Int = 0,
        rows: Int = 40
    ) async throws -> SearchResult {
        let url = searchURL(
            collection: collection,
            query: query,
            sortField: sortField,
            sortDirection: sortDirection,
            start: start,
            rows: rows
        )
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
        return SearchResult(docs: response.response.docs, totalCount: response.response.numFound)
    }

    public func fetchItemMetadata(_ identifier: String) async throws -> ArchiveItemMetadata {
        let url = metadataURL(for: identifier)
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(ArchiveItemMetadata.self, from: data)
    }
}
