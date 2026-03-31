import SwiftUI
import SwiftData
import RadioPlayer

struct ShowDetailView: View {
    let doc: SearchDoc

    @Environment(ArchiveAPI.self) private var api
    @Environment(AudioPlayerService.self) private var player
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ShowDetailViewModel?
    @State private var show: Show?
    @State private var selectedFilter: EpisodeStatus?

    var body: some View {
        Group {
            if let vm = viewModel {
                List {
                    // Show header
                    Section {
                        HStack(spacing: 16) {
                            AsyncCachedImage(
                                url: URL(string: "https://archive.org/services/img/\(doc.identifier)"),
                                title: doc.title ?? doc.identifier,
                                size: 100
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(doc.title ?? doc.identifier)
                                    .font(.headline)

                                if let creator = doc.creator?.first {
                                    Text(creator)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if let desc = doc.description {
                                    Text(stripHTML(desc) ?? desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Filter picker
                    if !vm.episodes.isEmpty {
                        Section {
                            Picker("Filter", selection: $selectedFilter) {
                                Text("All").tag(Optional<EpisodeStatus>.none)
                                ForEach(EpisodeStatus.allCases, id: \.self) { status in
                                    Text(status.displayName).tag(Optional(status))
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedFilter) { _, newValue in
                                vm.filterStatus = newValue
                            }
                        }
                    }

                    // Episodes
                    Section {
                        if vm.isLoading && vm.episodes.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView("Loading episodes…")
                                Spacer()
                            }
                        } else if vm.filteredEpisodes.isEmpty && !vm.isLoading {
                            ContentUnavailableView(
                                "No Episodes",
                                systemImage: "waveform",
                                description: Text(selectedFilter != nil ? "No \(selectedFilter!.displayName.lowercased()) episodes." : "No episodes found.")
                            )
                        } else {
                            ForEach(vm.filteredEpisodes, id: \.filename) { episode in
                                EpisodeRowView(
                                    episode: episode,
                                    onPlay: {
                                        player.setQueue(vm.filteredEpisodes, startingAt: vm.filteredEpisodes.firstIndex(where: { $0.filename == episode.filename }) ?? 0)
                                        player.play(episode: episode)
                                    },
                                    onDownload: {
                                        downloadManager.downloadEpisode(episode)
                                    }
                                )
                            }
                        }
                    }
                }
                .navigationTitle(doc.title ?? doc.identifier)
                .task {
                    if vm.episodes.isEmpty {
                        await vm.loadEpisodes()
                    }
                }
                .refreshable {
                    await vm.loadEpisodes()
                }
            }
        }
        .task {
            await setupShow()
        }
    }

    private func setupShow() async {
        // Fetch or create the Show record in SwiftData
        let identifier = doc.identifier
        let descriptor = FetchDescriptor<Show>(predicate: #Predicate { $0.identifier == identifier })
        let existing = try? modelContext.fetch(descriptor)

        let showRecord: Show
        if let found = existing?.first {
            showRecord = found
        } else {
            let new = Show(identifier: identifier, title: doc.title ?? identifier, collection: doc.identifier)
            new.creator = doc.creator?.first
            new.showDescription = doc.description
            new.date = doc.date
            new.downloads = doc.downloads ?? 0
            modelContext.insert(new)
            try? modelContext.save()
            showRecord = new
        }

        show = showRecord
        viewModel = ShowDetailViewModel(show: showRecord, api: api, modelContext: modelContext)
    }
}
