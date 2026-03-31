import Foundation

public final class PlaybackSpeedStore {
    public static let supportedSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    private static let key = "playbackSpeed"

    private let defaults: UserDefaults

    public var speed: Float {
        get {
            let stored = defaults.float(forKey: Self.key)
            let value = stored == 0 ? 1.0 : stored
            return clamped(value)
        }
        set {
            defaults.set(clamped(newValue), forKey: Self.key)
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func clamped(_ value: Float) -> Float {
        min(2.0, max(0.5, value))
    }
}
