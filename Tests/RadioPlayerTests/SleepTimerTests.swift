import Testing
import Foundation
@testable import RadioPlayer

@Suite("SleepTimer")
@MainActor
struct SleepTimerTests {

    @Test("Initially inactive with no time remaining")
    func initialState() {
        let timer = SleepTimer()
        #expect(timer.isActive == false)
        #expect(timer.remainingSeconds == 0)
        #expect(timer.selectedMinutes == 30)
    }

    @Test("start activates timer with remaining seconds")
    func start() async throws {
        let timer = SleepTimer()
        timer.start(minutes: 10)
        #expect(timer.isActive == true)
        #expect(timer.remainingSeconds > 0)
        #expect(timer.remainingSeconds <= 600)
        timer.cancel()
    }

    @Test("cancel deactivates timer")
    func cancel() {
        let timer = SleepTimer()
        timer.start(minutes: 5)
        timer.cancel()
        #expect(timer.isActive == false)
        #expect(timer.remainingSeconds == 0)
    }

    @Test("preset options are available")
    func presets() {
        #expect(SleepTimer.presets == [5, 10, 15, 20, 30, 45, 60])
    }

    @Test("formattedRemaining formats mm:ss correctly")
    func formattedRemaining() {
        let timer = SleepTimer()
        timer.start(minutes: 1)
        // Should be something like "1:00" or "0:59"
        let formatted = timer.formattedRemaining
        #expect(formatted.contains(":"))
        timer.cancel()
    }
}
