import Foundation

public enum EpisodeStatus: String, Codable, CaseIterable, Sendable {
    case new = "new"
    case inProgress = "inProgress"
    case completed = "completed"
    case notListened = "notListened"

    public var displayName: String {
        switch self {
        case .new: "New"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .notListened: "Not Listened"
        }
    }
}
