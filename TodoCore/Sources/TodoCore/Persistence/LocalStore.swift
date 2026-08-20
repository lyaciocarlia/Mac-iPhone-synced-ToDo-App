import Foundation

/// Persists the to-do list to a JSON file in the app's Application Support
/// directory so the list survives relaunches and is available offline.
public actor LocalStore {
    private let fileURL: URL

    public init(fileName: String = "todos.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent(fileName)
    }

    public func load() -> [TodoItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TodoItem].self, from: data)) ?? []
    }

    public func save(_ items: [TodoItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
