import SwiftUI
import RadioPlayer

struct CollectionListView: View {
    @Binding var selectedCollection: ArchiveCollection?

    var body: some View {
        List(selection: $selectedCollection) {
            Section("Collections") {
                ForEach(ArchiveCollection.allCases) { collection in
                    Label(collection.displayName, systemImage: collection.systemImage)
                        .tag(collection)
                }
            }

            Section {
                Label("Library", systemImage: "square.and.arrow.down")
                    .tag(Optional<ArchiveCollection>.none)
            }
        }
        .navigationTitle("Radio Player")
    }
}
