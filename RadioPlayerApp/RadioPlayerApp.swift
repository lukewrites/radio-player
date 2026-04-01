import SwiftUI
import SwiftData
import RadioPlayer

@main
struct RadioPlayerApp: App {
    @State private var audioPlayer = AudioPlayerService()
    @State private var downloadManager = DownloadManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var sleepTimer = SleepTimer()
    @State private var currentTheme: AppTheme = ThemeStore().theme
    private let api: ArchiveAPI = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            return ArchiveAPI(session: UITestMockURLSession())
        }
        #endif
        return ArchiveAPI()
    }()
    private let speedStore = PlaybackSpeedStore()
    private let themeStore = ThemeStore()

    var body: some Scene {
        WindowGroup {
            ContentView(currentTheme: $currentTheme)
                .environment(audioPlayer)
                .environment(downloadManager)
                .environment(networkMonitor)
                .environment(sleepTimer)
                .environment(api)
                .environment(\.appTheme, currentTheme)
                .tint(currentTheme.accent)
                .onAppear {
                    audioPlayer.configureRemoteCommands()
                    audioPlayer.playbackRate = speedStore.speed
                    networkMonitor.start()
                    sleepTimer.onTimerFired = { audioPlayer.pause() }
                }
                .onChange(of: audioPlayer.playbackRate) { _, newRate in
                    speedStore.speed = newRate
                }
                .onChange(of: currentTheme) { _, newTheme in
                    themeStore.theme = newTheme
                }
        }
        .modelContainer(for: [Show.self, Episode.self])
    }
}
