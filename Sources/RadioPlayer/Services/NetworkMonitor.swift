import Foundation
import Network
import Observation

@Observable
@MainActor
public final class NetworkMonitor {
    public var isConnected: Bool = true
    public var isExpensive: Bool = false   // cellular

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.radioplayer.networkmonitor")

    public init() {}

    public func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: monitorQueue)
    }

    public func stop() {
        monitor.cancel()
    }

    deinit {
        monitor.cancel()
    }
}
