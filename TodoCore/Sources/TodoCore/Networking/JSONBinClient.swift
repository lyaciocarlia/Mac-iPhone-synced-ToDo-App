import Foundation

public enum SyncError: Error, Equatable {
    case notConfigured
    case server(Int)
    case decoding
    case transport
}

/// Credentials for a free jsonbin.io bin. Both devices must be configured
/// with the same bin ID and key so they read/write the same remote list.
public struct SyncCredentials: Codable, Equatable, Sendable {
    public var binId: String
    public var apiKey: String

    public init(binId: String, apiKey: String) {
        self.binId = binId
        self.apiKey = apiKey
    }
}

/// Minimal client for jsonbin.io's REST API (https://jsonbin.io), a free
/// service for storing small JSON documents. The entire to-do list is
/// stored as a single JSON array in one bin.
public struct JSONBinClient: Sendable {
    private let credentials: SyncCredentials
    private static let baseURL = URL(string: "https://api.jsonbin.io/v3/b")!

    public init(credentials: SyncCredentials) {
        self.credentials = credentials
    }

    private struct Envelope: Codable {
        var record: [TodoItem]
    }

    public func fetch() async throws -> [TodoItem] {
        let url = Self.baseURL.appendingPathComponent(credentials.binId).appendingPathComponent("latest")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(credentials.apiKey, forHTTPHeaderField: "X-Master-Key")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SyncError.transport
        }
        try Self.validate(response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
            throw SyncError.decoding
        }
        return envelope.record
    }

    public func push(_ items: [TodoItem]) async throws {
        let url = Self.baseURL.appendingPathComponent(credentials.binId)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(credentials.apiKey, forHTTPHeaderField: "X-Master-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(items)

        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SyncError.transport
        }
        try Self.validate(response)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SyncError.server(code)
        }
    }
}
