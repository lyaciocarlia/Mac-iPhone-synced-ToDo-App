import Combine
import Foundation
import Network

/// Watches network reachability so the app can react the moment a device
/// comes back online and flush any changes made while offline.
@MainActor
public final class NetworkMonitor: ObservableObject {
    @Published public private(set) var isOnline: Bool = true

    /// Called once when the path transitions from offline to online.
    public var onBecomeOnline: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "TodoCore.NetworkMonitor")

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = online
                if wasOffline && online {
                    self.onBecomeOnline?()
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
