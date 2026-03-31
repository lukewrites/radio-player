import Foundation

public enum ArchiveCollection: String, CaseIterable, Identifiable, Sendable {
    case oldTimeRadio = "oldtimeradio"
    case radioBooks = "radiobooks"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .oldTimeRadio: "Old Time Radio"
        case .radioBooks: "Radio Books"
        }
    }

    public var systemImage: String {
        switch self {
        case .oldTimeRadio: "radio"
        case .radioBooks: "book.closed"
        }
    }
}
