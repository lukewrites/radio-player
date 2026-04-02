import Foundation

public struct BroadcastDateResolver: Sendable {

    // overrides["show_identifier"]["filename"] = "YYYY-MM-DD"
    private let overrides: [String: [String: String]]

    public init(overrides: [String: [String: String]] = [:]) {
        self.overrides = overrides
    }

    /// Load from the bundled JSON resource in Bundle.module.
    public static func fromBundle() throws -> BroadcastDateResolver {
        guard let url = Bundle.module.url(forResource: "broadcast_date_overrides", withExtension: "json") else {
            throw BroadcastDateResolverError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(OverrideFile.self, from: data)
        return BroadcastDateResolver(overrides: file.overrides)
    }

    /// Resolve broadcast date for an episode.
    /// Tier 1: parse from filename. Tier 2: look up manual override.
    public func resolve(filename: String, showIdentifier: String) -> Date? {
        if let parsed = parseDateFromFilename(filename) {
            return parsed
        }
        if let dateString = overrides[showIdentifier]?[filename] {
            return parseISO8601Date(dateString)
        }
        return nil
    }

    // MARK: - Internal (exposed for unit testing)

    /// Extract a broadcast date from a filename by finding an embedded YY-MM-DD or YYYY-MM-DD pattern.
    /// Two-digit years always map to 1900 + YY (all OTR content is 1920s–1960s).
    func parseDateFromFilename(_ filename: String) -> Date? {
        // Match YY-MM-DD or YYYY-MM-DD anywhere in the string
        let regex = #/(\d{2,4})-(\d{2})-(\d{2})/#
        guard let match = filename.firstMatch(of: regex) else { return nil }

        let yearString = String(match.1)
        let monthString = String(match.2)
        let dayString = String(match.3)

        guard let month = Int(monthString),
              let day = Int(dayString),
              month >= 1, month <= 12,
              day >= 1, day <= 31 else { return nil }

        let year: Int
        if yearString.count == 2, let twoDigit = Int(yearString) {
            year = 1900 + twoDigit
        } else if let fourDigit = Int(yearString) {
            year = fourDigit
        } else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(identifier: "UTC")

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: components)
    }

    // MARK: - Private

    private func parseISO8601Date(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    // MARK: - Codable

    private struct OverrideFile: Decodable {
        let overrides: [String: [String: String]]
    }
}

enum BroadcastDateResolverError: Error {
    case resourceNotFound
}
