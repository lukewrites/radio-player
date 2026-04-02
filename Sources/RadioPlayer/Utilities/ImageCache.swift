import Foundation

/// Thread-safe in-memory cache for image data keyed by URL.
public final class ImageCache: @unchecked Sendable {
    public static let shared = ImageCache()
    private var store: [URL: Data] = [:]
    private let lock = NSLock()

    public init() {}

    public subscript(url: URL) -> Data? {
        get { lock.withLock { store[url] } }
        set { lock.withLock { store[url] = newValue } }
    }

    public func clear() {
        lock.withLock { store.removeAll() }
    }
}
