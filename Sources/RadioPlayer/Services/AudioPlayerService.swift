import Foundation
import AVFoundation
import MediaPlayer
import Observation

@Observable
@MainActor
public final class AudioPlayerService {
    // Playback state
    public var isPlaying = false
    public var currentEpisode: Episode?
    public var currentTime: Double = 0
    public var duration: Double = 0
    public var isBuffering = false
    public var playbackRate: Float = 1.0

    // Queue
    public var queue: [Episode] = []
    public var queueIndex: Int = 0

    // Private AVPlayer
    private var player: AVPlayer?
    private var timeObserver: Any?

    public init() {}

    // MARK: - Playback Controls

    public func play(episode: Episode) {
        guard let url = episode.isDownloaded ? localFileURL(for: episode) : episode.streamURL else { return }

        let playerItem = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        if episode.playbackPosition > 0 {
            let time = CMTime(seconds: episode.playbackPosition, preferredTimescale: 600)
            player?.seek(to: time)
        }

        player?.rate = playbackRate
        setCurrentEpisode(episode)
        isPlaying = true
        configureAudioSession()
        setupTimeObserver()
        updateNowPlayingInfo()
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    public func resume() {
        player?.rate = playbackRate
        isPlaying = true
        updateNowPlayingInfo()
    }

    public func togglePlayPause() {
        if isPlaying { pause() } else { resume() }
    }

    public func seekTo(_ seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time)
        currentTime = seconds
        if let episode = currentEpisode {
            episode.playbackPosition = seconds
        }
        updateNowPlayingInfo()
    }

    public func skipForward(_ seconds: Double = 30) {
        seekTo(min(currentTime + seconds, duration))
    }

    public func skipBackward(_ seconds: Double = 15) {
        seekTo(max(currentTime - seconds, 0))
    }

    public func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        currentEpisode = nil
        currentTime = 0
        duration = 0
    }

    // MARK: - Queue Management

    public func setQueue(_ episodes: [Episode], startingAt index: Int) {
        queue = episodes
        queueIndex = index
        if index < episodes.count {
            setCurrentEpisode(episodes[index])
        }
    }

    @discardableResult
    public func nextInQueue() -> Bool {
        let nextIndex = queueIndex + 1
        guard nextIndex < queue.count else { return false }
        queueIndex = nextIndex
        setCurrentEpisode(queue[nextIndex])
        return true
    }

    // MARK: - State Management (testable without AVPlayer)

    public func setCurrentEpisode(_ episode: Episode) {
        currentEpisode = episode
        duration = episode.duration ?? 0
        currentTime = episode.playbackPosition

        if episode.episodeStatus == .new || episode.episodeStatus == .notListened {
            episode.episodeStatus = .inProgress
        }
        episode.lastPlayedAt = Date()
    }

    public func updateProgress(currentTime: Double, duration: Double) {
        self.currentTime = currentTime
        self.duration = duration

        guard let episode = currentEpisode else { return }
        episode.playbackPosition = currentTime
        episode.lastPlayedAt = Date()

        if duration > 0, currentTime / duration >= 0.95 {
            episode.episodeStatus = .completed
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
        #endif
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        if let existing = timeObserver {
            player?.removeTimeObserver(existing)
        }

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                let seconds = time.seconds
                let dur = self.player?.currentItem?.duration.seconds ?? 0
                self.updateProgress(currentTime: seconds, duration: dur.isNaN ? 0 : dur)
                self.updateNowPlayingInfo()
            }
        }
    }

    // MARK: - Now Playing Info Center

    private func updateNowPlayingInfo() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = currentEpisode?.title ?? currentEpisode?.filename ?? ""
        info[MPMediaItemPropertyArtist] = currentEpisode?.show?.title ?? ""
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackRate) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Remote Commands

    public func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [30]
        center.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipForward() }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipBackward() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seekTo(event.positionTime) }
            return .success
        }
    }

    // MARK: - Local File Support

    private func localFileURL(for episode: Episode) -> URL? {
        guard let path = episode.localFilePath else { return nil }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
    }
}
