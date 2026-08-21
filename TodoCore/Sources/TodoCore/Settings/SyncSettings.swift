import Combine
import Foundation

/// The mockapi.io resource URL entered by the user. Stored in UserDefaults.
/// Use the same URL on every device you want to sync.
@MainActor
public final class SyncSettings: ObservableObject {
    @Published public var apiURL: String {
        didSet {
            guard apiURL != oldValue else { return }
            UserDefaults.standard.set(apiURL, forKey: "todosync.apiURL")
        }
    }

    public var isConfigured: Bool {
        let trimmed = apiURL.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && URL(string: trimmed) != nil
    }

    public init() {
        self.apiURL = UserDefaults.standard.string(forKey: "todosync.apiURL") ?? ""
    }
}
