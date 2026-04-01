import Foundation

public enum ArchiveCollection: String, CaseIterable, Identifiable, Sendable {

    // OTRR catch-all
    case oldTimeRadio       = "oldtimeradio"
    // OTRR genres
    case otrrDrama          = "otrr_drama"
    case otrrComedy         = "otrr_comedy"
    case otrrMystery        = "otrr_mystery"
    case otrrAdventure      = "otrr_adventure"
    case otrrWestern        = "otrr_western"
    case otrrScienceFiction = "otrr_scifi"
    case otrrHorror         = "otrr_horror"
    // Other
    case radioBooks         = "radiobooks"

    public var id: String { rawValue }

    // MARK: - Category

    public enum Category: Sendable, Equatable {
        case otrr
        case general
    }

    public var category: Category {
        switch self {
        case .radioBooks: .general
        default: .otrr
        }
    }

    // MARK: - Display

    public var displayName: String {
        switch self {
        case .oldTimeRadio:       "All Shows"
        case .otrrDrama:          "Drama"
        case .otrrComedy:         "Comedy"
        case .otrrMystery:        "Mystery & Detective"
        case .otrrAdventure:      "Adventure"
        case .otrrWestern:        "Westerns"
        case .otrrScienceFiction: "Science Fiction"
        case .otrrHorror:         "Horror & Suspense"
        case .radioBooks:         "Radio Books"
        }
    }

    public var systemImage: String {
        switch self {
        case .oldTimeRadio:       "radio"
        case .otrrDrama:          "theatermasks"
        case .otrrComedy:         "face.smiling"
        case .otrrMystery:        "magnifyingglass"
        case .otrrAdventure:      "airplane"
        case .otrrWestern:        "star"
        case .otrrScienceFiction: "antenna.radiowaves.left.and.right"
        case .otrrHorror:         "moon.stars"
        case .radioBooks:         "book.closed"
        }
    }

    public var description: String {
        switch self {
        case .oldTimeRadio:
            "The complete Old Time Radio Researchers Group catalog — hundreds of classic American radio shows, fully restored and properly tagged."
        case .otrrDrama:
            "Dramatic radio plays and anthology series from the golden age of radio."
        case .otrrComedy:
            "Classic comedy programmes featuring legends like Jack Benny, Bob Hope, and Burns & Allen."
        case .otrrMystery:
            "Whodunits, private eye serials, and crime dramas to keep you guessing."
        case .otrrAdventure:
            "Action and adventure serials — heroes, explorers, and daring escapades."
        case .otrrWestern:
            "Gunfighters, lawmen, and frontier justice from the American West."
        case .otrrScienceFiction:
            "Rocket ships, alien worlds, and the future as imagined by radio's golden age."
        case .otrrHorror:
            "Spine-tingling suspense and horror from the masters of radio terror."
        case .radioBooks:
            "Audiobooks and spoken-word recordings of classic public-domain literature."
        }
    }

    // MARK: - Search

    public var baseQuery: String {
        switch self {
        case .oldTimeRadio:
            "identifier:OTRR_*"
        case .otrrDrama:
            #"identifier:OTRR_* AND subject:"Drama""#
        case .otrrComedy:
            #"identifier:OTRR_* AND subject:"Comedy""#
        case .otrrMystery:
            #"identifier:OTRR_* AND (subject:"Mystery" OR subject:"Detective")"#
        case .otrrAdventure:
            #"identifier:OTRR_* AND subject:"Adventure""#
        case .otrrWestern:
            #"identifier:OTRR_* AND subject:"Western""#
        case .otrrScienceFiction:
            #"identifier:OTRR_* AND subject:"Science Fiction""#
        case .otrrHorror:
            #"identifier:OTRR_* AND (subject:"Horror" OR subject:"Suspense")"#
        case .radioBooks:
            "collection:radiobooks"
        }
    }
}
