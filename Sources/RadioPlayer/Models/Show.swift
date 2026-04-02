import Foundation
import SwiftData

@Model
public final class Show: Hashable {
    @Attribute(.unique) public var identifier: String
    public var title: String
    public var creator: String?
    public var showDescription: String?
    public var date: String?
    public var downloads: Int
    public var collection: String
    public var isFavorite: Bool
    public var lastAccessedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Episode.show)
    public var episodes: [Episode]

    public var thumbnailImageURL: URL? {
        URL(string: "https://archive.org/services/img/\(identifier)")
    }


    public init(identifier: String, title: String, collection: String) {
        self.identifier = identifier
        self.title = title
        self.collection = collection
        self.downloads = 0
        self.isFavorite = false
        self.episodes = []
    }
}
