import Foundation
import SwiftData
import Observation

public struct DownloadProgress: Sendable {
    public var downloadedBytes: Int64
    public var totalBytes: Int64
    public var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(downloadedBytes) / Double(totalBytes)
    }

    public init(downloadedBytes: Int64, totalBytes: Int64) {
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }
}

@Observable
@MainActor
public final class DownloadManager: NSObject {
    // Key: "identifier/filename"
    public var activeDownloads: [String: DownloadProgress] = [:]

    @ObservationIgnored private var tasks: [String: URLSessionDownloadTask] = [:]
    @ObservationIgnored private var _session: URLSession?

    private var session: URLSession {
        if let s = _session { return s }
        let config = URLSessionConfiguration.background(withIdentifier: "com.radioplayer.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        let s = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        _session = s
        return s
    }

    public override init() {}

    // MARK: - Key helpers

    private func key(for episode: Episode) -> String? {
        guard let id = episode.show?.identifier else { return nil }
        return "\(id)/\(episode.filename)"
    }

    // MARK: - Public API

    public func localFilePath(for episode: Episode) -> String? {
        guard let id = episode.show?.identifier else { return nil }
        return "Downloads/\(id)/\(episode.filename)"
    }

    public func isDownloading(_ episode: Episode) -> Bool {
        guard let k = key(for: episode) else { return false }
        return activeDownloads[k] != nil
    }

    public func progress(for episode: Episode) -> DownloadProgress? {
        guard let k = key(for: episode) else { return nil }
        return activeDownloads[k]
    }

    public func downloadEpisode(_ episode: Episode) {
        guard let url = episode.streamURL else { return }
        guard let k = key(for: episode) else { return }
        guard activeDownloads[k] == nil else { return }

        activeDownloads[k] = DownloadProgress(downloadedBytes: 0, totalBytes: 0)
        let task = session.downloadTask(with: url)
        tasks[k] = task
        task.resume()
    }

    public func cancelDownload(_ episode: Episode) {
        guard let k = key(for: episode) else { return }
        tasks[k]?.cancel()
        tasks[k] = nil
        activeDownloads[k] = nil
    }

    public func markDownloadComplete(for episode: Episode, context: ModelContext) {
        guard let path = localFilePath(for: episode) else { return }
        episode.isDownloaded = true
        episode.localFilePath = path
        if let k = key(for: episode) {
            activeDownloads[k] = nil
            tasks[k] = nil
        }
        try? context.save()
    }

    public func deleteDownload(for episode: Episode, context: ModelContext) {
        // Remove local file if it exists
        if let path = episode.localFilePath {
            let fullURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(path)
            try? FileManager.default.removeItem(at: fullURL)
        }
        episode.isDownloaded = false
        episode.localFilePath = nil
        try? context.save()
    }

    public func updateProgress(for episode: Episode, bytesWritten: Int64, totalBytes: Int64) {
        guard let k = key(for: episode) else { return }
        activeDownloads[k] = DownloadProgress(downloadedBytes: bytesWritten, totalBytes: totalBytes)
    }

    // MARK: - Test helpers

    #if DEBUG
    public func simulateActiveDownload(for episode: Episode) {
        guard let k = key(for: episode) else { return }
        activeDownloads[k] = DownloadProgress(downloadedBytes: 0, totalBytes: 0)
    }
    #endif
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let url = downloadTask.originalRequest?.url else { return }
        let urlString = url.absoluteString

        Task { @MainActor in
            // Find matching task key
            guard let matchingKey = self.tasks.first(where: { $0.value.originalRequest?.url == url })?.key else { return }

            // Parse identifier/filename from key
            let parts = matchingKey.split(separator: "/", maxSplits: 1)
            guard parts.count == 2 else { return }
            let identifier = String(parts[0])
            let filename = String(parts[1])

            // Determine destination
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destDir = docsURL.appendingPathComponent("Downloads/\(identifier)")
            let destURL = destDir.appendingPathComponent(filename)

            do {
                try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.moveItem(at: location, to: destURL)
            } catch {
                print("DownloadManager: failed to move file: \(error)")
            }
            _ = urlString // suppress unused warning
        }
    }

    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let url = downloadTask.originalRequest?.url else { return }
        Task { @MainActor in
            guard let matchingKey = self.tasks.first(where: { $0.value.originalRequest?.url == url })?.key else { return }
            self.activeDownloads[matchingKey] = DownloadProgress(
                downloadedBytes: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite
            )
        }
    }
}
