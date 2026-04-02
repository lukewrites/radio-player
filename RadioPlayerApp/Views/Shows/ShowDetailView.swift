import SwiftUI
import SwiftData
import RadioPlayer

struct ShowDetailView: View {
    private let identifier: String
    private let displayTitle: String
    private let displayCreator: String?
    private let displayDescription: String?
    private let preloadedShow: Show?

    @Environment(ArchiveAPI.self) private var api
    @Environment(AudioPlayerService.self) private var player
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ShowDetailViewModel?
    @State private var show: Show?
    @State private var selectedFilter: EpisodeStatus?

    // Init from collection browser (SearchDoc)
    init(doc: SearchDoc) {
        self.identifier = doc.identifier
        self.displayTitle = doc.title ?? doc.identifier
        self.displayCreator = doc.creator?.first
        self.displayDescription = doc.description
        self.preloadedShow = nil
    }

    // Init from Favorites (Show already exists in SwiftData)
    init(show: Show) {
        self.identifier = show.identifier
        self.displayTitle = show.title
        self.displayCreator = show.creator
        self.displayDescription = show.showDescription
        self.preloadedShow = show
    }

    var body: some View {
        Group {
            if let vm = viewModel {
                List {
                    // Show header
                    Section {
                        HStack(spacing: 16) {
                            AsyncCachedImage(
                                url: URL(string: "https://archive.org/services/img/\(identifier)"),
                                title: displayTitle,
                                size: 100
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(displayTitle)
                                    .font(.headline)

                                if let creator = displayCreator {
                                    Text(creator)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if let desc = displayDescription {
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
                .navigationTitle(displayTitle)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            show?.isFavorite.toggle()
                            try? modelContext.save()
                        } label: {
                            Image(systemName: show?.isFavorite == true ? "star.fill" : "star")
                                .foregroundStyle(show?.isFavorite == true ? .yellow : .primary)
                        }
                        .accessibilityLabel(show?.isFavorite == true ? "Remove from Favorites" : "Add to Favorites")
                    }
                }
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
        if let preloaded = preloadedShow {
            show = preloaded
            viewModel = ShowDetailViewModel(show: preloaded, api: api, modelContext: modelContext)
            return
        }

        let descriptor = FetchDescriptor<Show>(predicate: #Predicate { $0.identifier == identifier })
        let existing = try? modelContext.fetch(descriptor)

        let showRecord: Show
        if let found = existing?.first {
            showRecord = found
        } else {
            let new = Show(identifier: identifier, title: displayTitle, collection: identifier)
            new.creator = displayCreator
            new.showDescription = displayDescription
            modelContext.insert(new)
            try? modelContext.save()
            showRecord = new
        }

        show = showRecord
        viewModel = ShowDetailViewModel(show: showRecord, api: api, modelContext: modelContext)
    }
}
