import SwiftUI
import TodoCore

@main
struct TodoSyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
