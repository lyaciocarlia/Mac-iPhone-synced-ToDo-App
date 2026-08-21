import Foundation

/// Syncs the local list against the mockapi.io REST resource using proper
/// CRUD operations:
///   - Local items with no remoteId  → POST (create on remote)
///   - Local items marked isDeleted  → DELETE on remote, then drop locally
///   - Local items newer than remote → PUT (push update)
///   - Remote items newer than local → pull update
///   - Remote items not in local     → added by another device, pull them
///   - Local items whose remoteId vanished from remote → deleted elsewhere, drop
@MainActor
public final class SyncEngine {
    private let local: LocalStore
    private let urlProvider: () -> String?

    public init(local: LocalStore, apiURL urlProvider: @escaping () -> String?) {
        self.local = local
        self.urlProvider = urlProvider
    }

    public func sync(localItems: [TodoItem]) async -> Result<[TodoItem], SyncError> {
        guard let urlString = urlProvider(),
              !urlString.trimmingCharacters(in: .whitespaces).isEmpty,
              let resourceURL = URL(string: urlString) else {
            return .failure(.notConfigured)
        }

        let client = MockAPIClient(resourceURL: resourceURL)
        do {
            let remoteItems = try await client.fetchAll()

            // Index remote items by their mockapi id for O(1) lookup.
            var remoteById: [String: TodoItem] = [:]
            for item in remoteItems {
                if let rid = item.remoteId { remoteById[rid] = item }
            }

            var result: [TodoItem] = []

            for var localItem in localItems {
                if localItem.isDeleted {
                    // Best effort: delete from remote if it was ever pushed.
                    if let rid = localItem.remoteId {
                        try? await client.delete(remoteId: rid)
                    }
                    // Drop tombstone from local — deletion is permanent.
                    continue
                }

                if localItem.remoteId == nil {
                    // Never synced → create on remote, store the assigned id.
                    let rid = try await client.create(localItem)
                    localItem.remoteId = rid
                    result.append(localItem)
                } else if let remote = remoteById[localItem.remoteId!] {
                    if localItem.updatedAt >= remote.updatedAt {
                        // Local is newer → push.
                        try await client.update(localItem)
                        result.append(localItem)
                    } else {
                        // Remote is newer → accept.
                        result.append(remote)
                    }
                    remoteById.removeValue(forKey: localItem.remoteId!)
                } else {
                    // remoteId exists locally but not on remote →
                    // the other device deleted it. Drop from local.
                }
            }

            // Remaining remote items are new (added on another device).
            for (_, remoteItem) in remoteById where !remoteItem.isDeleted {
                result.append(remoteItem)
            }

            let sorted = result.sorted { $0.createdAt < $1.createdAt }
            await local.save(sorted)
            return .success(sorted)

        } catch let err as SyncError {
            return .failure(err)
        } catch {
            return .failure(.transport)
        }
    }
}
