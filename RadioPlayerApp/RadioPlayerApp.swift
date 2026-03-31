import SwiftUI
import SwiftData
import RadioPlayer

@main
struct RadioPlayerApp: App {
    @State private var audioPlayer = AudioPlayerService()
    @State private var downloadManager = DownloadManager()
    private let api = ArchiveAPI()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioPlayer)
                .environment(downloadManager)
                .environment(api)
                .onAppear {
                    audioPlayer.configureRemoteCommands()
                }
        }
        .modelContainer(for: [Show.self, Episode.self])
    }
}
