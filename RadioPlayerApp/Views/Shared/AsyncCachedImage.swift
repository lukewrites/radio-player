import SwiftUI

/// Loads a remote image asynchronously with an in-memory cache.
/// Falls back to StylizedCoverView if the load fails.
struct AsyncCachedImage: View {
    let url: URL?
    let title: String
    var size: CGFloat = 120

    @State private var image: Image?
    @State private var loading = false

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.12))
            } else {
                StylizedCoverView(title: title, size: size)
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard !loading, let url else { return }

        // Check in-memory cache first
        if let cached = ImageCache.shared[url] {
            image = cached
            return
        }

        loading = true
        defer { loading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            #if os(macOS)
            if let nsImage = NSImage(data: data) {
                let result = Image(nsImage: nsImage)
                ImageCache.shared[url] = result
                image = result
            }
            #else
            if let uiImage = UIImage(data: data) {
                let result = Image(uiImage: uiImage)
                ImageCache.shared[url] = result
                image = result
            }
            #endif
        } catch {
            // Silently fall back to StylizedCoverView
        }
    }
}

// MARK: - Simple in-memory image cache

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private var store: [URL: Image] = [:]
    private let lock = NSLock()

    subscript(url: URL) -> Image? {
        get {
            lock.withLock { store[url] }
        }
        set {
            lock.withLock { store[url] = newValue }
        }
    }
}
