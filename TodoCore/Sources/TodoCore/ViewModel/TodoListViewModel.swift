import Combine
import Foundation

@MainActor
public final class TodoListViewModel: ObservableObject {
    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case offline
        case error
    }

    @Published public private(set) var items: [TodoItem] = []
    @Published public private(set) var status: SyncStatus = .idle
    @Published public private(set) var errorMessage: String?

    public let settings: SyncSettings

    private let local: LocalStore
    private let network: NetworkMonitor
    private var syncTask: Task<Void, Never>?

    public var visibleItems: [TodoItem] {
        items.filter { !$0.isDeleted }
    }

    public init(
        settings: SyncSettings = SyncSettings(),
        local: LocalStore = LocalStore(),
        network: NetworkMonitor = NetworkMonitor()
    ) {
        self.settings = settings
        self.local = local
        self.network = network
        network.onBecomeOnline = { [weak self] in
            self?.sync()
        }
    }

    public func loadAndSync() {
        Task {
            items = await local.load()
            sync()
        }
    }

    public func addItem(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed))
        persistAndSync()
    }

    public func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isDone.toggle()
        items[index].updatedAt = Date()
        persistAndSync()
    }

    public func rename(_ item: TodoItem, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = trimmed
        items[index].updatedAt = Date()
        persistAndSync()
    }

    public func delete(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isDeleted = true
        items[index].updatedAt = Date()
        persistAndSync()
    }

    public func removeItems(at offsets: IndexSet) {
        let visible = visibleItems
        for offset in offsets {
            delete(visible[offset])
        }
    }

    public func sync() {
        guard network.isOnline else {
            status = .offline
            return
        }
        guard settings.isConfigured else {
            status = .idle
            return
        }

        syncTask?.cancel()
        syncTask = Task {
            status = .syncing
            let engine = SyncEngine(local: local, settings: { [weak self] in self?.settings.credentials })
            let result = await engine.syncMerging(local: items)
            switch result {
            case .success(let merged):
                items = merged
                status = .idle
                errorMessage = nil
            case .failure(let error):
                status = .error
                errorMessage = Self.message(for: error)
            }
        }
    }

    private func persistAndSync() {
        let snapshot = items
        Task { await local.save(snapshot) }
        sync()
    }

    private static func message(for error: SyncError) -> String {
        switch error {
        case .notConfigured:
            return "Add your jsonbin.io Bin ID and API key in Settings to enable sync."
        case .server(let code):
            return "Sync failed (server returned \(code))."
        case .decoding:
            return "Sync failed (couldn't read the remote list)."
        case .transport:
            return "Sync failed (network error). Will retry automatically."
        }
    }
}
