import Foundation

public enum SyncError: Error, Equatable {
    case notConfigured
    case server(Int)
    case decoding
    case transport
}

/// REST client for a mockapi.io resource. Each TodoItem is a separate
/// resource (standard GET / POST / PUT / DELETE), so an empty collection
/// is perfectly valid — no "blank bin" problem.
///
/// Set up on mockapi.io:
///   1. Create a project → copy the base URL (e.g. https://abc.mockapi.io/api/v1)
///   2. Add a resource named "todos" with these String/Boolean fields:
///      title (String), isDone (Boolean), isDeleted (Boolean),
///      createdAt (String), updatedAt (String)
///   3. Paste the full resource URL into the app's Settings on every device.
public struct MockAPIClient: Sendable {
    private let resourceURL: URL

    public init(resourceURL: URL) {
        self.resourceURL = resourceURL
    }

    // Shape mockapi returns for each item.
    struct RemoteItem: Decodable {
        var id: String
        var title: String
        var isDone: Bool
        var isDeleted: Bool
        var createdAt: String
        var updatedAt: String

        func toTodoItem() -> TodoItem {
            TodoItem(
                remoteId: id,
                title: title,
                isDone: isDone,
                isDeleted: isDeleted,
                createdAt: Self.parseDate(createdAt),
                updatedAt: Self.parseDate(updatedAt)
            )
        }

        private static func parseDate(_ string: String) -> Date {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = f.date(from: string) { return d }
            f.formatOptions = [.withInternetDateTime]
            return f.date(from: string) ?? Date()
        }
    }

    // Body sent to mockapi when creating or updating an item.
    private struct ItemBody: Encodable {
        var title: String
        var isDone: Bool
        var isDeleted: Bool
        var createdAt: String
        var updatedAt: String
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private func body(for item: TodoItem) throws -> Data {
        let b = ItemBody(
            title: item.title,
            isDone: item.isDone,
            isDeleted: item.isDeleted,
            createdAt: Self.iso8601.string(from: item.createdAt),
            updatedAt: Self.iso8601.string(from: item.updatedAt)
        )
        return try JSONEncoder().encode(b)
    }

    public func fetchAll() async throws -> [TodoItem] {
        let (data, response) = try await perform(URLRequest(url: resourceURL))
        try Self.validate(response)
        guard let items = try? JSONDecoder().decode([RemoteItem].self, from: data) else {
            throw SyncError.decoding
        }
        return items.map { $0.toTodoItem() }
    }

    /// Creates a new item and returns the mockapi-assigned id.
    public func create(_ item: TodoItem) async throws -> String {
        var request = URLRequest(url: resourceURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try body(for: item)
        let (data, response) = try await perform(request)
        try Self.validate(response)
        guard let created = try? JSONDecoder().decode(RemoteItem.self, from: data) else {
            throw SyncError.decoding
        }
        return created.id
    }

    public func update(_ item: TodoItem) async throws {
        guard let remoteId = item.remoteId else { return }
        var request = URLRequest(url: resourceURL.appendingPathComponent(remoteId))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try body(for: item)
        let (_, response) = try await perform(request)
        try Self.validate(response)
    }

    public func delete(remoteId: String) async throws {
        var request = URLRequest(url: resourceURL.appendingPathComponent(remoteId))
        request.httpMethod = "DELETE"
        let (_, response) = try await perform(request)
        try Self.validate(response)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw SyncError.transport
        }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SyncError.server((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }
}
