import Foundation
import SwiftData

@Model
public final class Episode {
    public var filename: String
    public var title: String?
    public var track: String?
    public var duration: Double?
    public var fileSize: Int64?
    public var format: String

    // Status tracking
    public var status: String
    public var playbackPosition: Double
    public var lastPlayedAt: Date?

    // Download tracking
    public var isDownloaded: Bool
    public var localFilePath: String?

    public var show: Show?

    public var episodeStatus: EpisodeStatus {
        get { EpisodeStatus(rawValue: status) ?? .new }
        set { status = newValue.rawValue }
    }

    public var streamURL: URL? {
        guard let identifier = show?.identifier else { return nil }
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        return URL(string: "https://archive.org/download/\(identifier)/\(encoded)")
    }

    public init(filename: String, format: String) {
        self.filename = filename
        self.format = format
        self.status = EpisodeStatus.new.rawValue
        self.playbackPosition = 0
        self.isDownloaded = false
    }
}
