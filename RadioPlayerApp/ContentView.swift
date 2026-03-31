import SwiftUI
import RadioPlayer

struct ContentView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var selectedCollection: ArchiveCollection? = .oldTimeRadio
    @State private var selectedShow: SearchDoc?

    var body: some View {
        ZStack(alignment: .bottom) {
            adaptiveNavigation

            if !networkMonitor.isConnected {
                offlineBanner
            }

            if player.currentEpisode != nil {
                MiniPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(duration: 0.35), value: player.currentEpisode != nil)
            }
        }
    }

    private var offlineBanner: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("No Internet Connection")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.red.opacity(0.9), in: Capsule())
            .padding(.top, 8)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(duration: 0.35), value: networkMonitor.isConnected)
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
                LibraryView()
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
                LibraryView()
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
