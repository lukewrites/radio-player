import Foundation

public struct ArchiveSearchResponse: Codable, Sendable {
    public let response: SearchResponseBody
}

public struct SearchResponseBody: Codable, Sendable {
    public let numFound: Int
    public let start: Int
    public let docs: [SearchDoc]
}

public struct SearchDoc: Codable, Sendable, Hashable {
    public static func == (lhs: SearchDoc, rhs: SearchDoc) -> Bool { lhs.identifier == rhs.identifier }
    public func hash(into hasher: inout Hasher) { hasher.combine(identifier) }
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

// MARK: - Item Metadata Response

public struct ArchiveItemMetadata: Codable, Sendable {
    public let metadata: ItemMetadataFields?
    public let files: [ArchiveFile]
}

public struct ItemMetadataFields: Codable, Sendable {
    public let identifier: String?
    public let title: String?
    public let description: String?
    public let creator: [String]?
    public let subject: [String]?
    public let date: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        date = try container.decodeIfPresent(String.self, forKey: .date)

        // creator: String or [String]
        if let single = try? container.decode(String.self, forKey: .creator) {
            creator = [single]
        } else if let array = try? container.decode([String].self, forKey: .creator) {
            creator = array
        } else {
            creator = nil
        }

        // subject: String or [String]
        if let single = try? container.decode(String.self, forKey: .subject) {
            subject = [single]
        } else if let array = try? container.decode([String].self, forKey: .subject) {
            subject = array
        } else {
            subject = nil
        }
    }
}

public struct ArchiveFile: Codable, Sendable {
    public let name: String
    public let source: String?
    public let format: String?
    public let size: String?
    public let length: String?
    public let title: String?
    public let track: String?
    public let creator: String?

    public var isPlayableAudio: Bool {
        guard let format else { return false }
        let lower = format.lowercased()
        return lower.contains("mp3") || lower.contains("vorbis") || lower.contains("ogg")
    }
}
