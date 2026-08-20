import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SyncSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bin ID", text: $settings.binId)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                    SecureField("API Key (X-Master-Key)", text: $settings.apiKey)
                        .autocorrectionDisabled()
                } header: {
                    Text("jsonbin.io Sync")
                } footer: {
                    Text("Create a free bin at jsonbin.io (start it with an empty array: []), then paste its Bin ID and your X-Master-Key here on every device you want to sync. Both devices must use the same Bin ID and key.")
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
        .frame(minWidth: 420, minHeight: 260)
        #endif
    }
}
