import Foundation
import Observation

@Observable
@MainActor
public final class SleepTimer {
    public static let presets: [Int] = [5, 10, 15, 20, 30, 45, 60]

    public var isActive = false
    public var remainingSeconds: Int = 0
    public var selectedMinutes: Int = 30

    public var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Called when the timer fires — the app should pause playback
    public var onTimerFired: (() -> Void)?

    private var task: Task<Void, Never>?

    public init() {}

    public func start(minutes: Int) {
        cancel()
        selectedMinutes = minutes
        remainingSeconds = minutes * 60
        isActive = true

        task = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, self.isActive else { return }
                    if self.remainingSeconds > 0 {
                        self.remainingSeconds -= 1
                    }
                    if self.remainingSeconds == 0 {
                        self.isActive = false
                        self.onTimerFired?()
                        self.task?.cancel()
                    }
                }
            }
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
        isActive = false
        remainingSeconds = 0
    }
}
