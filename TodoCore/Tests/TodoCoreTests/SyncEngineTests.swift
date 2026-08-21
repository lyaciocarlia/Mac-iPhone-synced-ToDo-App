import XCTest
@testable import TodoCore

final class SyncEngineTests: XCTestCase {
    func testNewerUpdatedAtWinsRegardlessOfSide() {
        let id = UUID()
        let older = TodoItem(
            id: id, title: "Old title", isDone: false,
            createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0)
        )
        let newer = TodoItem(
            id: id, title: "New title", isDone: true,
            createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(SyncEngine.merge(local: [newer], remote: [older]).first?.title, "New title")
        XCTAssertEqual(SyncEngine.merge(local: [older], remote: [newer]).first?.title, "New title")
    }

    func testMergeUnionsItemsFromBothSides() {
        let a = TodoItem(title: "A")
        let b = TodoItem(title: "B")
        let merged = SyncEngine.merge(local: [a], remote: [b])
        XCTAssertEqual(Set(merged.map(\.id)), Set([a.id, b.id]))
    }

    func testDeletionTombstonePropagatesWhenNewer() {
        let id = UUID()
        let deleted = TodoItem(
            id: id, title: "Gone", isDeleted: true,
            createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 100)
        )
        let remoteStillThere = TodoItem(
            id: id, title: "Gone",
            createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0)
        )

        let merged = SyncEngine.merge(local: [deleted], remote: [remoteStillThere])
        XCTAssertEqual(merged.first?.isDeleted, true)
    }
}
