import Testing
import Foundation
@testable import RadioPlayer

@Suite("PlaybackSpeedStore")
struct PlaybackSpeedStoreTests {

    // Use a fresh UserDefaults suite per test run to avoid cross-test pollution
    private func makeSuite() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Default speed is 1.0")
    func defaultSpeed() {
        let store = PlaybackSpeedStore(defaults: makeSuite())
        #expect(store.speed == 1.0)
    }

    @Test("Saved speed is restored on next load")
    func saveAndLoad() {
        let defaults = makeSuite()
        let store1 = PlaybackSpeedStore(defaults: defaults)
        store1.speed = 1.5

        let store2 = PlaybackSpeedStore(defaults: defaults)
        #expect(store2.speed == 1.5)
    }

    @Test("Invalid speed is clamped to valid range")
    func clampSpeed() {
        let store = PlaybackSpeedStore(defaults: makeSuite())
        store.speed = 10.0
        #expect(store.speed <= 2.0)

        store.speed = 0.1
        #expect(store.speed >= 0.5)
    }

    @Test("All supported speeds are valid")
    func supportedSpeeds() {
        #expect(PlaybackSpeedStore.supportedSpeeds == [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
    }
}
