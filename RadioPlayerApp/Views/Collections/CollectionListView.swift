import SwiftUI
import RadioPlayer

struct CollectionListView: View {
    @Binding var selectedDestination: SidebarDestination?
    @Binding var currentTheme: AppTheme
    @State private var showSettings = false

    var body: some View {
        List(selection: $selectedDestination) {
            Label("Favorites", systemImage: "star.fill")
                .tag(SidebarDestination.favorites)

            Section("Old Time Radio") {
                ForEach(ArchiveCollection.allCases.filter { $0.category == .otrr }) { collection in
                    Label(collection.displayName, systemImage: collection.systemImage)
                        .tag(SidebarDestination.collection(collection))
                }
            }

            Section("Other") {
                ForEach(ArchiveCollection.allCases.filter { $0.category == .general }) { collection in
                    Label(collection.displayName, systemImage: collection.systemImage)
                        .tag(SidebarDestination.collection(collection))
                }
                Label("Library", systemImage: "square.and.arrow.down")
                    .tag(SidebarDestination.library)
            }
        }
        .navigationTitle("Radio Player")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(currentTheme: $currentTheme)
        }
    }
}
