import Foundation

public struct ArchiveSearchResponse: Codable, Sendable {
    public let response: SearchResponseBody
}

public struct SearchResponseBody: Codable, Sendable {
    public let numFound: Int
    public let start: Int
    public let docs: [SearchDoc]
}

public struct SearchDoc: Codable, Sendable {
    public let identifier: String
    public let title: String?
    public let description: String?
    public let creator: [String]?
    public let date: String?
    public let downloads: Int?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        downloads = try container.decodeIfPresent(Int.self, forKey: .downloads)

        // creator can be String or [String] from archive.org
        if let single = try? container.decode(String.self, forKey: .creator) {
            creator = [single]
        } else if let array = try? container.decode([String].self, forKey: .creator) {
            creator = array
        } else {
            creator = nil
        }
    }
}
