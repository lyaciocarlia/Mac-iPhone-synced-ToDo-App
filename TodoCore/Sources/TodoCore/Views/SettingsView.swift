import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SyncSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://…mockapi.io/api/v1/todos", text: $settings.apiURL)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled()
                } header: {
                    Text("mockapi.io Sync")
                } footer: {
                    Text("""
                        1. Sign up free at mockapi.io and create a project.
                        2. Add a resource named "todos" with these fields: title (String), isDone (Boolean), isDeleted (Boolean), createdAt (String), updatedAt (String).
                        3. Paste the full resource URL above (e.g. https://abc123.mockapi.io/api/v1/todos).
                        4. Enter the same URL on every device to sync them. No login required.
                        """)
                }
            }
            .navigationTitle("Sync Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 300)
        #endif
    }
}
