import XCTest

/// Diagnostic test — run manually to inspect the accessibility tree when
/// adding new UI tests. Not intended for CI.
final class DebugTests: XCTestCase {
    func testPrintAccessibilityTree() throws {
        throw XCTSkip("Diagnostic only — run manually by removing this skip")
    }
}
