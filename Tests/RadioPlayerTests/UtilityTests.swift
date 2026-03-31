import Testing
import Foundation
@testable import RadioPlayer

@Suite("Utilities")
struct UtilityTests {

    // MARK: - Duration Formatting

    @Test("Format seconds as h:mm:ss for long durations")
    func formatLongDuration() {
        #expect(formatDuration(3661) == "1:01:01")
    }

    @Test("Format seconds as m:ss for short durations")
    func formatShortDuration() {
        #expect(formatDuration(125) == "2:05")
    }

    @Test("Format zero seconds")
    func formatZero() {
        #expect(formatDuration(0) == "0:00")
    }

    @Test("Format seconds from string (archive.org returns strings)")
    func formatDurationFromString() {
        #expect(formatDuration(fromString: "1802.5") == "30:02")
        #expect(formatDuration(fromString: nil) == nil)
        #expect(formatDuration(fromString: "not a number") == nil)
    }

    // MARK: - HTML Stripping

    @Test("Strip simple HTML tags from description")
    func stripSimpleHTML() {
        #expect(stripHTML("<p>Hello world</p>") == "Hello world")
    }

    @Test("Strip nested HTML tags")
    func stripNestedHTML() {
        #expect(stripHTML("<div><b>Bold</b> and <i>italic</i></div>") == "Bold and italic")
    }

    @Test("Return plain text unchanged")
    func plainTextPassthrough() {
        #expect(stripHTML("No tags here") == "No tags here")
    }

    @Test("Handle nil input")
    func stripHTMLNil() {
        let input: String? = nil
        #expect(stripHTML(input) == nil)
    }

    @Test("Decode common HTML entities")
    func decodeHTMLEntities() {
        #expect(stripHTML("Tom &amp; Jerry") == "Tom & Jerry")
    }
}
