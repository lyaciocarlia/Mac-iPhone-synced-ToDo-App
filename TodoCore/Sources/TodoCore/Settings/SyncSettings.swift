import Combine
import Foundation

/// User-entered jsonbin.io credentials. The bin ID is stored in
/// UserDefaults; the API key is stored in the Keychain. Enter the same
/// values on every device to sync them together.
@MainActor
public final class SyncSettings: ObservableObject {
    @Published public var binId: String {
        didSet {
            guard binId != oldValue else { return }
            UserDefaults.standard.set(binId, forKey: Keys.binId)
        }
    }

    @Published public var apiKey: String {
        didSet {
            guard apiKey != oldValue else { return }
            KeychainStore.set(apiKey, for: Keys.apiKey)
        }
    }

    public var isConfigured: Bool {
        !binId.trimmingCharacters(in: .whitespaces).isEmpty && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public var credentials: SyncCredentials? {
        isConfigured ? SyncCredentials(binId: binId, apiKey: apiKey) : nil
    }

    private enum Keys {
        static let binId = "todosync.binId"
        static let apiKey = "todosync.apiKey"
    }

    public init() {
        self.binId = UserDefaults.standard.string(forKey: Keys.binId) ?? ""
        self.apiKey = KeychainStore.get(Keys.apiKey) ?? ""
    }
}
