import SwiftUI
import RadioPlayer

struct CollectionBrowserView: View {
    let collection: ArchiveCollection
    @Binding var selectedShow: SearchDoc?

    @Environment(ArchiveAPI.self) private var api
    @State private var viewModel: CollectionBrowserViewModel?

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)
    ]

    var body: some View {
        Group {
            if let vm = viewModel {
                ScrollView {
                    if vm.shows.isEmpty && vm.isLoading {
                        ProgressView("Loading shows…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 80)
                    } else if vm.shows.isEmpty && !vm.isLoading {
                        ContentUnavailableView(
                            vm.searchText.isEmpty ? "No Shows" : "No Results",
                            systemImage: "radio",
                            description: Text(vm.searchText.isEmpty
                                ? "No shows found in \(collection.displayName)."
                                : "No shows match \"\(vm.searchText)\".")
                        )
                        .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(vm.shows, id: \.identifier) { doc in
                                NavigationLink(value: doc) {
                                    ShowCardView(doc: doc)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(doc.title ?? doc.identifier)
                                .onAppear {
                                    // Trigger next page when last item appears
                                    if doc.identifier == vm.shows.last?.identifier {
                                        Task { await vm.loadMore() }
                                    }
                                }
                            }

                            if vm.isLoading && !vm.shows.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .gridCellColumns(columns.count)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
                .searchable(text: Binding(
                    get: { vm.searchText },
                    set: { text in
                        Task { await vm.search(text) }
                    }
                ), prompt: "Search shows")
                .refreshable {
                    await vm.loadInitial()
                }
                .alert("Error", isPresented: Binding(
                    get: { vm.errorMessage != nil },
                    set: { if !$0 { vm.errorMessage = nil } }
                )) {
                    Button("OK") { vm.errorMessage = nil }
                } message: {
                    Text(vm.errorMessage ?? "")
                }
            } else {
                ProgressView("Loading…")
            }
        }
        .navigationTitle(collection.displayName)
        .navigationDestination(for: SearchDoc.self) { doc in
            ShowDetailView(doc: doc)
        }
        .task {
            if viewModel == nil {
                viewModel = CollectionBrowserViewModel(collection: collection, api: api)
            }
            guard let vm = viewModel else { return }
            // Retry until shows load, a real error occurs, or the view is gone
            while vm.shows.isEmpty && vm.errorMessage == nil && !Task.isCancelled {
                await vm.loadInitial()
            }
        }
    }
}
