import Foundation

public struct TodoItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var remoteId: String?   // mockapi-assigned id; nil until first successful sync
    public var title: String
    public var isDone: Bool
    public var isDeleted: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        remoteId: String? = nil,
        title: String,
        isDone: Bool = false,
        isDeleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.remoteId = remoteId
        self.title = title
        self.isDone = isDone
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
