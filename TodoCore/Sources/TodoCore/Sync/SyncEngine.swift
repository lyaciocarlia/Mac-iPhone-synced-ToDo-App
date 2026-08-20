import Foundation

/// Pulls the remote list, merges it with the local list, pushes the merged
/// result back, and saves it locally. Conflicts are resolved per-item using
/// "last write wins" based on `updatedAt`, so an edit made offline on one
/// device is never silently lost when the other device also changed
/// something.
@MainActor
public final class SyncEngine {
    private let local: LocalStore
    private let credentialsProvider: () -> SyncCredentials?

    public init(local: LocalStore, settings credentialsProvider: @escaping () -> SyncCredentials?) {
        self.local = local
        self.credentialsProvider = credentialsProvider
    }

    public func syncMerging(local currentItems: [TodoItem]) async -> Result<[TodoItem], SyncError> {
        guard let credentials = credentialsProvider() else { return .failure(.notConfigured) }
        let client = JSONBinClient(credentials: credentials)
        do {
            let remoteItems = try await client.fetch()
            let merged = Self.merge(local: currentItems, remote: remoteItems)
            try await client.push(merged)
            await local.save(merged)
            return .success(merged)
        } catch let error as SyncError {
            return .failure(error)
        } catch {
            return .failure(.transport)
        }
    }

    /// Merges two snapshots of the list by unioning items by `id` and, for
    /// items present on both sides, keeping the one with the newer
    /// `updatedAt`. Deletions are tombstones (`isDeleted = true`) rather
    /// than removals, so a delete made offline still propagates once both
    /// sides sync.
    public static func merge(local: [TodoItem], remote: [TodoItem]) -> [TodoItem] {
        var byId: [UUID: TodoItem] = [:]
        for item in remote {
            byId[item.id] = item
        }
        for item in local {
            if let existing = byId[item.id] {
                byId[item.id] = item.updatedAt >= existing.updatedAt ? item : existing
            } else {
                byId[item.id] = item
            }
        }
        return byId.values.sorted { $0.createdAt < $1.createdAt }
    }
}
