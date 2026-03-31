import SwiftUI
import SwiftData
import RadioPlayer

@main
struct RadioPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Show.self, Episode.self])
    }
}
