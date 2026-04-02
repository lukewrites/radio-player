import SwiftUI
import RadioPlayer

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
            }
        }
        // Task lives on the outer Group so it fires even when an image is already
        // displayed. Resetting image = nil clears any stale thumbnail from a
        // previous URL before loading the new one.
        .task(id: url) {
            image = nil
            await loadImage()
        }
    }

    private func loadImage() async {
        guard !loading, let url else { return }

        if let cached = ImageCache.shared[url] {
            #if os(macOS)
            if let nsImage = NSImage(data: cached) { image = Image(nsImage: nsImage) }
            #else
            if let uiImage = UIImage(data: cached) { image = Image(uiImage: uiImage) }
            #endif
            return
        }

        loading = true
        defer { loading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            ImageCache.shared[url] = data
            #if os(macOS)
            if let nsImage = NSImage(data: data) { image = Image(nsImage: nsImage) }
            #else
            if let uiImage = UIImage(data: data) { image = Image(uiImage: uiImage) }
            #endif
        } catch {
            // Silently fall back to StylizedCoverView
        }
    }
}
