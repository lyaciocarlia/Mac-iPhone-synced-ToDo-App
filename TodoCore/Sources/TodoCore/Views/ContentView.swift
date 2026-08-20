import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = TodoListViewModel()
    @State private var newTitle = ""
    @State private var showingSettings = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar
                List {
                    ForEach(viewModel.visibleItems) { item in
                        TodoRow(item: item, onToggle: { viewModel.toggle(item) })
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    viewModel.delete(item)
                                }
                            }
                    }
                    .onDelete(perform: viewModel.removeItems)
                }
                .listStyle(.plain)
                addBar
            }
            .navigationTitle("To-Dos")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Sync Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: viewModel.settings)
            }
            .onAppear { viewModel.loadAndSync() }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 460)
        #endif
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            statusIcon
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch viewModel.status {
        case .idle:
            Image(systemName: "checkmark.icloud").foregroundStyle(.green)
        case .syncing:
            ProgressView().scaleEffect(0.7)
        case .offline:
            Image(systemName: "wifi.slash").foregroundStyle(.orange)
        case .error:
            Image(systemName: "exclamationmark.icloud").foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch viewModel.status {
        case .idle:
            return viewModel.settings.isConfigured ? "Synced" : "Not syncing — add Sync Settings"
        case .syncing:
            return "Syncing…"
        case .offline:
            return "Offline — changes saved on this device"
        case .error:
            return viewModel.errorMessage ?? "Sync error"
        }
    }

    private var addBar: some View {
        HStack {
            TextField("New to-do", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addNewItem)
            Button("Add", action: addNewItem)
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }

    private func addNewItem() {
        viewModel.addItem(title: newTitle)
        newTitle = ""
    }
}
