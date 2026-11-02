import SwiftData
import SwiftUI

struct AddEntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date

    init(initialDate: Date = .now) {
        _date = State(initialValue: min(initialDate, .now))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PoopMascot(expression: .calm)
                        .frame(width: 72, height: 72)
                    Text("什么时候便便的呀？")
                        .font(.rounded(20, weight: .bold))
                        .foregroundStyle(Theme.ink)

                    HStack(spacing: 10) {
                        quickChip("1 小时前", hours: -1)
                        quickChip("今早 8 点", morningOf: 0)
                        quickChip("昨天这时", hours: -24)
                    }

                    DatePicker(
                        "时间",
                        selection: $date,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Theme.poop)
                    .card()
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("补记一次")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("记下来") { save() }
                        .fontWeight(.bold)
                }
            }
            .tint(Theme.poop)
        }
    }

    private func quickChip(_ title: String, hours: Int? = nil, morningOf dayOffset: Int? = nil) -> some View {
        Button {
            let calendar = Calendar.current
            if let hours {
                date = calendar.date(byAdding: .hour, value: hours, to: .now) ?? .now
            } else if let dayOffset,
                      let day = calendar.date(byAdding: .day, value: dayOffset, to: .now),
                      let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day) {
                date = min(morning, .now)
            }
        } label: {
            Text(title)
                .font(.rounded(14, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.cream))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        context.insert(PoopEntry(timestamp: min(date, .now)))
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddEntrySheet()
        .modelContainer(PreviewData.container)
}
