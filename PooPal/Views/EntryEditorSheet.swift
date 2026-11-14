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
            ScrollView {
                VStack(spacing: 16) {
                    timeCard
                    BristolPicker(selection: $bristolType)
                        .card()
                    noteCard
                    if isEditing {
                        Button(role: .destructive) {
                            confirmingDelete = true
                        } label: {
                            Label("删除这条记录", systemImage: "trash")
                                .font(.rounded(16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Theme.pink.opacity(0.5)))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.ink)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "编辑记录" : "补记一次")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "保存" : "记下来") { save() }
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog("删除后不能恢复哦", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("删除", role: .destructive) { delete() }
            }
            .tint(Theme.poop)
        }
    }

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                IconBadge(icon: .symbol("clock.fill"), tint: Theme.cream, size: 30)
                Text("什么时候呀？")
                    .font(.rounded(17, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            DatePicker("时间", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
            if !isEditing {
                HStack(spacing: 8) {
                    quickChip("1 小时前") { Calendar.current.date(byAdding: .hour, value: -1, to: .now) }
                    quickChip("今早 8 点") { Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) }
                    quickChip("昨天这时") { Calendar.current.date(byAdding: .day, value: -1, to: .now) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                IconBadge(icon: .symbol("pencil"), tint: Theme.cream, size: 30)
                Text("小备注")
                    .font(.rounded(17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("可不填")
                    .font(.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            TextField("比如：昨晚吃了火锅、有点肚子痛…", text: $note, axis: .vertical)
                .font(.rounded(16))
                .lineLimit(2...5)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.background))
        }
        .card()
    }

    private func quickChip(_ title: String, date makeDate: @escaping () -> Date?) -> some View {
        Button {
            if let value = makeDate() { date = min(value, .now) }
        } label: {
            Text(title)
                .font(.rounded(13, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.lavender.opacity(0.7)))
        }
        .buttonStyle(.plain)
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
