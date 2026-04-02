import Testing
import Foundation
@testable import RadioPlayer

@Suite("BroadcastDateResolver")
struct BroadcastDateResolverTests {

    private func components(from date: Date) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.dateComponents([.year, .month, .day], from: date)
    }

    // MARK: - parseDateFromFilename

    @Test("parses two-digit year from Dragnet-style filename")
    func parseTwoDigitYear() {
        let resolver = BroadcastDateResolver()
        let date = resolver.parseDateFromFilename("Dragnet_49-09-17_Cop_Killing.mp3")
        let c = components(from: date!)
        #expect(c.year == 1949)
        #expect(c.month == 9)
        #expect(c.day == 17)
    }

    @Test("parses four-digit year from Jack Benny-style filename")
    func parseFourDigitYear() {
        let resolver = BroadcastDateResolver()
        let date = resolver.parseDateFromFilename("JB 1943-10-17 Casablanca.mp3")
        let c = components(from: date!)
        #expect(c.year == 1943)
        #expect(c.month == 10)
        #expect(c.day == 17)
    }

    @Test("returns nil when filename has no date pattern")
    func noDateReturnsNil() {
        let resolver = BroadcastDateResolver()
        #expect(resolver.parseDateFromFilename("01 Abbott and Costello Audio Bio.mp3") == nil)
    }

    @Test("parses date mid-filename after show name prefix")
    func parsesDateMidFilename() {
        let resolver = BroadcastDateResolver()
        let date = resolver.parseDateFromFilename("Abbott and Costello 40-07-31 Guest - Madame Lazonga.mp3")
        let c = components(from: date!)
        #expect(c.year == 1940)
        #expect(c.month == 7)
        #expect(c.day == 31)
    }

    @Test("parses date with underscores separating components")
    func parsesDateWithUnderscores() {
        let resolver = BroadcastDateResolver()
        let date = resolver.parseDateFromFilename("Dragnet_49-09-17_Cop_Killing.mp3")
        #expect(date != nil)
    }

    @Test("two-digit year maps to 1900s, never 2000s")
    func twoDigitYearIs1900s() {
        let resolver = BroadcastDateResolver()
        let date = resolver.parseDateFromFilename("Show_50-01-01_Episode.mp3")!
        let c = components(from: date)
        #expect(c.year == 1950)
    }

    // MARK: - resolve (override fallback)

    @Test("returns filename-parsed date when override also exists")
    func filenameBeatsOverride() {
        let resolver = BroadcastDateResolver(overrides: [
            "OTRR_Dragnet_Singles": ["Dragnet_49-09-17_Cop_Killing.mp3": "1999-01-01"]
        ])
        let date = resolver.resolve(filename: "Dragnet_49-09-17_Cop_Killing.mp3",
                                    showIdentifier: "OTRR_Dragnet_Singles")
        let c = components(from: date!)
        #expect(c.year == 1949)
    }

    @Test("falls back to override date when filename has no date")
    func fallsBackToOverride() {
        let resolver = BroadcastDateResolver(overrides: [
            "OTRR_Some_Show": ["nodatefile.mp3": "1952-03-15"]
        ])
        let date = resolver.resolve(filename: "nodatefile.mp3",
                                    showIdentifier: "OTRR_Some_Show")
        let c = components(from: date!)
        #expect(c.year == 1952)
        #expect(c.month == 3)
        #expect(c.day == 15)
    }

    @Test("returns nil when filename has no date and no override entry")
    func returnsNilWithNoData() {
        let resolver = BroadcastDateResolver()
        #expect(resolver.resolve(filename: "nodatefile.mp3", showIdentifier: "OTRR_Unknown") == nil)
    }

    @Test("override for a different show does not match")
    func overrideDoesNotCrossShows() {
        let resolver = BroadcastDateResolver(overrides: [
            "OTRR_Show_A": ["episode.mp3": "1952-03-15"]
        ])
        #expect(resolver.resolve(filename: "episode.mp3", showIdentifier: "OTRR_Show_B") == nil)
    }
}
