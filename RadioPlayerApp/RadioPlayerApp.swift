import SwiftUI
import SwiftData
import RadioPlayer

@main
struct RadioPlayerApp: App {
    @State private var audioPlayer = AudioPlayerService()
    @State private var downloadManager = DownloadManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var sleepTimer = SleepTimer()
    private let api = ArchiveAPI()
    private let speedStore = PlaybackSpeedStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioPlayer)
                .environment(downloadManager)
                .environment(networkMonitor)
                .environment(sleepTimer)
                .environment(api)
                .onAppear {
                    audioPlayer.configureRemoteCommands()
                    audioPlayer.playbackRate = speedStore.speed
                    networkMonitor.start()
                    sleepTimer.onTimerFired = { audioPlayer.pause() }
                }
                .onChange(of: audioPlayer.playbackRate) { _, newRate in
                    speedStore.speed = newRate
                }
        }
        .modelContainer(for: [Show.self, Episode.self])
    }
}
