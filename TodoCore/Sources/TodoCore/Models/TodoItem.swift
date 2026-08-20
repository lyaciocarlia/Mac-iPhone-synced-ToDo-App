import Foundation

public struct TodoItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var isDone: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}
