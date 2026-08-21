import SwiftUI

struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .strikethrough(item.isDone)
                .foregroundStyle(item.isDone ? .secondary : .primary)

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}
