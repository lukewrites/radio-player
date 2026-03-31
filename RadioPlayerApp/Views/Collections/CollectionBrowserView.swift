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
                                Button {
                                    selectedShow = doc
                                } label: {
                                    ShowCardView(doc: doc)
                                }
                                .buttonStyle(.plain)
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
                .navigationTitle(collection.displayName)
                .searchable(text: Binding(
                    get: { vm.searchText },
                    set: { text in
                        Task { await vm.search(text) }
                    }
                ), prompt: "Search shows")
                .task {
                    if vm.shows.isEmpty {
                        await vm.loadInitial()
                    }
                }
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
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CollectionBrowserViewModel(collection: collection, api: api)
            }
        }
    }
}
