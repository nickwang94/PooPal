import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(ReminderSettings.inactivityEnabledKey, store: SharedStore.defaults)
    private var inactivityOn = true
    @AppStorage(ReminderSettings.inactivityDaysKey, store: SharedStore.defaults)
    private var inactivityDays = ReminderSettings.defaultInactivityDays
    @AppStorage(ReminderSettings.dailyEnabledKey, store: SharedStore.defaults)
    private var dailyOn = false
    @AppStorage(ReminderSettings.dailyMinutesKey, store: SharedStore.defaults)
    private var dailyMinutes = ReminderSettings.defaultDailyMinutes

    @State private var notificationsDenied = false

    @State private var usePassword = false
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var shareItem: ShareItem?

    @State private var importing = false
    @State private var pendingImport: Data?
    @State private var askingPassword = false
    @State private var importPassword = ""
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                remindersSection
                backupSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.fontWeight(.bold)
                }
            }
            .tint(Theme.poop)
            .onChange(of: inactivityOn) { remindersChanged() }
            .onChange(of: inactivityDays) { remindersChanged() }
            .onChange(of: dailyOn) { remindersChanged() }
            .onChange(of: dailyMinutes) { remindersChanged() }
            .task { await refreshPermissionState() }
            .sheet(item: $shareItem) { item in
                ActivityView(items: [item.url])
                    .presentationDetents([.medium, .large])
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                handlePicked(result)
            }
            .alert("这个备份有密码", isPresented: $askingPassword) {
                SecureField("备份密码", text: $importPassword)
                Button("导入") { runImport(password: importPassword) }
                Button("取消", role: .cancel) { pendingImport = nil }
            } message: {
                Text("请输入导出时设置的密码")
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("好的", role: .cancel) {}
            }
        }
    }

    // MARK: Reminders

    private var remindersSection: some View {
        Section {
            Toggle(isOn: $inactivityOn) {
                rowLabel("好久没记录提醒", detail: "超过 \(inactivityDays) 天没有记录时，上午 \(ReminderSettings.inactivityHour) 点提醒你", symbol: "bell.badge.fill", tint: Theme.peach)
            }
            if inactivityOn {
                Stepper(value: $inactivityDays, in: 1...14) {
                    Text("几天没记录就提醒：\(inactivityDays) 天")
                        .font(.rounded(15, weight: .medium))
                        .foregroundStyle(Theme.ink)
                }
            }
            Toggle(isOn: $dailyOn) {
                rowLabel("每日小提醒", detail: "每天固定时间问问你今天便便了吗", symbol: "alarm.fill", tint: Theme.sky)
            }
            if dailyOn {
                DatePicker("提醒时间", selection: dailyTime, displayedComponents: .hourAndMinute)
                    .font(.rounded(15, weight: .medium))
            }
            if notificationsDenied && (inactivityOn || dailyOn) {
                Label("通知权限没有打开：请到 iPhone 设置 → 通知 → PooPal 里允许通知", systemImage: "exclamationmark.circle.fill")
                    .font(.rounded(13))
                    .foregroundStyle(Theme.poop)
            }
        } header: {
            sectionHeader("提醒")
        }
        .listRowBackground(Theme.card)
    }

    private var dailyTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: dailyMinutes / 60, minute: dailyMinutes % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
            dailyMinutes = (comps.hour ?? 21) * 60 + (comps.minute ?? 0)
        }
    }

    private func remindersChanged() {
        let latest = DataActions.latestEntryDate(context)
        Task {
            await ReminderScheduler.reschedule(lastEntry: latest, requestPermission: true)
            await refreshPermissionState()
        }
    }

    private func refreshPermissionState() async {
        notificationsDenied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    // MARK: Backup

    private var passwordProblem: String? {
        guard usePassword else { return nil }
        if password.count < 4 { return "密码至少 4 位" }
        if password != passwordConfirm { return "两次输入的密码不一样" }
        return nil
    }

    private var backupSection: some View {
        Section {
            Toggle(isOn: $usePassword.animation()) {
                rowLabel("给备份加密码", detail: "加密后只有输入密码才能导入；密码忘了就打不开哦", symbol: "lock.fill", tint: Theme.lavender)
            }
            if usePassword {
                SecureField("设置密码（至少 4 位）", text: $password)
                SecureField("再输入一次", text: $passwordConfirm)
                if let problem = passwordProblem, !password.isEmpty {
                    Text(problem)
                        .font(.rounded(13))
                        .foregroundStyle(Theme.poop)
                }
            }
            Button(action: export) {
                rowLabel("导出备份", detail: "生成 JSON 文件，可以存到「文件」、发给自己或 AirDrop", symbol: "square.and.arrow.up.fill", tint: Theme.mint)
            }
            .disabled(passwordProblem != nil)
            Button {
                importing = true
            } label: {
                rowLabel("导入备份", detail: "合并到现有记录，重复的会自动跳过", symbol: "square.and.arrow.down.fill", tint: Theme.butter)
            }
        } header: {
            sectionHeader("备份")
        }
        .listRowBackground(Theme.card)
    }

    private func export() {
        do {
            let url = try DataActions.exportBackup(context, password: usePassword ? password : nil)
            shareItem = ShareItem(url: url)
        } catch {
            message = "导出失败：\(error.localizedDescription)"
        }
    }

    private func handlePicked(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            pendingImport = data
            if BackupCodec.isEncrypted(data) {
                importPassword = ""
                askingPassword = true
            } else {
                runImport(password: nil)
            }
        } catch {
            message = "读取文件失败：\(error.localizedDescription)"
        }
    }

    private func runImport(password: String?) {
        guard let data = pendingImport else { return }
        do {
            let file = try BackupCodec.decode(data, password: password)
            let plan = try DataActions.importBackup(file, into: context)
            pendingImport = nil
            message = "导入完成：\(plan.summary)"
        } catch let error as BackupError {
            if error == .wrongPassword {
                message = error.localizedDescription
            } else {
                pendingImport = nil
                message = error.localizedDescription
            }
        } catch {
            pendingImport = nil
            message = "导入失败：\(error.localizedDescription)"
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            HStack(spacing: 12) {
                PoopMascot(expression: .happy)
                    .frame(width: 44, height: 44)
                Text("记录只保存在这台 iPhone 上，不需要登录。换手机前记得先导出备份哦。")
                    .font(.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            sectionHeader("关于 PooPal")
        }
        .listRowBackground(Theme.card)
    }

    // MARK: Helpers

    private func rowLabel(_ title: String, detail: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            IconBadge(icon: .symbol(symbol), tint: tint.opacity(0.7), size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rounded(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.rounded(14, weight: .bold))
            .foregroundStyle(Theme.inkSoft)
    }
}

struct ShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
