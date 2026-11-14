import SwiftData
import SwiftUI

/// Add a past entry (`entry == nil`) or edit an existing one: time, Bristol type, note.
struct EntryEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: PoopEntry?

    @State private var date: Date
    @State private var bristolType: Int?
    @State private var note: String
    @State private var confirmingDelete = false

    init(entry: PoopEntry? = nil, initialDate: Date = .now) {
        self.entry = entry
        _date = State(initialValue: min(entry?.timestamp ?? initialDate, .now))
        _bristolType = State(initialValue: entry?.bristolType)
        _note = State(initialValue: entry?.note ?? "")
    }

    private var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("时间", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    if !isEditing {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                quickChip("1 小时前") { Calendar.current.date(byAdding: .hour, value: -1, to: .now) }
                                quickChip("今早 8 点") { Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) }
                                quickChip("昨晚 10 点") {
                                    Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    BristolPicker(selection: $bristolType)
                        .padding(.vertical, 6)
                } header: {
                    Text("形态 · 布里斯托分类")
                }
                .listRowBackground(Theme.surface)

                Section {
                    TextField("比如：昨晚吃了火锅、有点肚子痛", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("备注")
                }
                .listRowBackground(Theme.surface)

                if isEditing {
                    Section {
                        Button("删除这条记录", role: .destructive) { confirmingDelete = true }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.ground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "编辑记录" : "补记一次")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "保存" : "记录") { save() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("删除后不能恢复", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("删除", role: .destructive) { delete() }
            }
        }
        .tint(Theme.glaze)
    }

    private func quickChip(_ title: String, date makeDate: @escaping () -> Date?) -> some View {
        Button(title) {
            if let value = makeDate() { date = min(value, .now) }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = trimmed.isEmpty ? nil : trimmed
        let time = min(date, .now)
        if let entry {
            entry.timestamp = time
            entry.bristolType = bristolType
            entry.note = cleanNote
        } else {
            context.insert(PoopEntry(timestamp: time, bristolType: bristolType, note: cleanNote))
        }
        DataActions.didChange(context, requestNotificationPermission: !isEditing)
        dismiss()
    }

    private func delete() {
        guard let entry else { return }
        context.delete(entry)
        DataActions.didChange(context)
        dismiss()
    }
}

#Preview {
    EntryEditorSheet()
        .modelContainer(PreviewData.container)
}
