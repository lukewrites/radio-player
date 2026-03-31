import SwiftUI
import SwiftData
import RadioPlayer

struct LibraryView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: LibraryViewModel?
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if let vm = viewModel {
                Picker("Library Section", selection: $selectedTab) {
                    Text("Continue").tag(0)
                    Text("Completed").tag(1)
                    Text("Downloads").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    switch selectedTab {
                    case 0:
                        inProgressSection(vm)
                    case 1:
                        completedSection(vm)
                    case 2:
                        downloadsSection(vm)
                    default:
                        EmptyView()
                    }
                }
                .listStyle(.plain)
                .refreshable { vm.load() }
            }
        }
        .navigationTitle("Library")
        .task {
            if viewModel == nil {
                viewModel = LibraryViewModel(modelContext: modelContext)
                viewModel?.load()
            }
        }
    }

    @ViewBuilder
    private func inProgressSection(_ vm: LibraryViewModel) -> some View {
        if vm.inProgressEpisodes.isEmpty {
            ContentUnavailableView(
                "Nothing In Progress",
                systemImage: "play.circle",
                description: Text("Episodes you've started will appear here.")
            )
        } else {
            ForEach(vm.inProgressEpisodes, id: \.filename) { episode in
                libraryEpisodeRow(episode, vm: vm)
            }
        }
    }

    @ViewBuilder
    private func completedSection(_ vm: LibraryViewModel) -> some View {
        if vm.completedEpisodes.isEmpty {
            ContentUnavailableView(
                "Nothing Completed",
                systemImage: "checkmark.circle",
                description: Text("Episodes you've finished will appear here.")
            )
        } else {
            ForEach(vm.completedEpisodes, id: \.filename) { episode in
                libraryEpisodeRow(episode, vm: vm)
            }
        }
    }

    @ViewBuilder
    private func downloadsSection(_ vm: LibraryViewModel) -> some View {
        if vm.downloadedEpisodes.isEmpty {
            ContentUnavailableView(
                "No Downloads",
                systemImage: "icloud.and.arrow.down",
                description: Text("Download episodes to listen offline.")
            )
        } else {
            ForEach(vm.downloadedEpisodes, id: \.filename) { episode in
                libraryEpisodeRow(episode, vm: vm)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let episode = vm.downloadedEpisodes[index]
                    downloadManager.deleteDownload(for: episode, context: modelContext)
                }
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func libraryEpisodeRow(_ episode: Episode, vm: LibraryViewModel) -> some View {
        EpisodeRowView(
            episode: episode,
            onPlay: {
                player.play(episode: episode)
            },
            onDownload: {
                downloadManager.downloadEpisode(episode)
            }
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                episode.episodeStatus = .notListened
                episode.playbackPosition = 0
                try? modelContext.save()
                vm.load()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
        }
    }
}
