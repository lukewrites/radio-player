import SwiftUI
import RadioPlayer

struct ContentView: View {
    @Environment(AudioPlayerService.self) private var player
    @State private var selectedCollection: ArchiveCollection? = .oldTimeRadio
    @State private var selectedShow: SearchDoc?

    var body: some View {
        ZStack(alignment: .bottom) {
            adaptiveNavigation

            if player.currentEpisode != nil {
                MiniPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(duration: 0.35), value: player.currentEpisode != nil)
            }
        }
    }

    @ViewBuilder
    private var adaptiveNavigation: some View {
        #if os(macOS)
        macLayout
        #else
        iOSLayout
        #endif
    }

    private var macLayout: some View {
        NavigationSplitView {
            CollectionListView(selectedCollection: $selectedCollection)
        } content: {
            if let collection = selectedCollection {
                CollectionBrowserView(collection: collection, selectedShow: $selectedShow)
            } else {
                ContentUnavailableView("Select a Collection", systemImage: "radio")
            }
        } detail: {
            if let show = selectedShow {
                ShowDetailView(doc: show)
            } else {
                ContentUnavailableView("Select a Show", systemImage: "waveform")
            }
        }
    }

    private var iOSLayout: some View {
        // iPhone uses compact split view; iPad gets three-column automatically
        NavigationSplitView {
            CollectionListView(selectedCollection: $selectedCollection)
        } content: {
            if let collection = selectedCollection {
                CollectionBrowserView(collection: collection, selectedShow: $selectedShow)
            } else {
                ContentUnavailableView("Select a Collection", systemImage: "radio")
            }
        } detail: {
            if let show = selectedShow {
                ShowDetailView(doc: show)
            } else {
                ContentUnavailableView("Select a Show", systemImage: "waveform")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AudioPlayerService())
}
