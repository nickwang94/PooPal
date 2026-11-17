import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .system

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
            Form {
                appearanceSection
                remindersSection
                backupSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.ground.ignoresSafeArea())
            .navigationTitle("设置")
            .fontDesign(.rounded)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.fontWeight(.semibold)
                }
            }
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
            .alert("这个备份设置了密码", isPresented: $askingPassword) {
                SecureField("备份密码", text: $importPassword)
                Button("导入") { runImport(password: importPassword) }
                Button("取消", role: .cancel) { pendingImport = nil }
            } message: {
                Text("请输入导出时设置的密码。")
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("好", role: .cancel) {}
            }
        }
        .tint(Theme.accent)
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            Picker(selection: $appearance) {
                ForEach(Appearance.allCases) { Text($0.title).tag($0) }
            } label: {
                SettingLabel("外观", symbol: "circle.lefthalf.filled", color: Color(hex: 0x7A4BA0))
            }
            .pickerStyle(.menu)
        } header: {
            Text("看起来")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Reminders

    private var remindersSection: some View {
        Section {
            Toggle(isOn: $inactivityOn) {
                SettingLabel("太久没来时提醒我", symbol: "bell.badge.fill", color: Theme.dryInk)
            }
            if inactivityOn {
                Stepper(value: $inactivityDays, in: 1...14) {
                    Label {
                        LabeledContent("超过几天算太久", value: "\(inactivityDays) 天")
                    } icon: {
                        Color.clear.frame(width: 29, height: 29)
                    }
                }
            }
            Toggle(isOn: $dailyOn) {
                SettingLabel("每天提醒我记一下", symbol: "alarm.fill", color: Theme.looseInk)
            }
            if dailyOn {
                DatePicker("提醒时间", selection: dailyTime, displayedComponents: .hourAndMinute)
            }
            if notificationsDenied && (inactivityOn || dailyOn) {
                Label("通知权限已关闭。请到 iPhone「设置 › 通知 › PooPal」里允许通知。", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.alert)
            }
        } header: {
            Text("小提醒")
        } footer: {
            Text(inactivityOn ? "超过 \(inactivityDays) 天没来的话，上午 \(ReminderSettings.inactivityHour) 点轻轻提醒你。" : "")
        }
        .listRowBackground(Theme.surface)
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
        if password != passwordConfirm { return "两次输入的密码不一致" }
        return nil
    }

    private var backupSection: some View {
        Section {
            Toggle(isOn: $usePassword.animation()) {
                SettingLabel("给备份加个密码", symbol: "lock.fill", color: Color(hex: 0x7A6A7E))
            }
            if usePassword {
                SecureField("设置密码（至少 4 位）", text: $password)
                SecureField("再输入一次", text: $passwordConfirm)
                if let problem = passwordProblem, !password.isEmpty {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(Theme.alert)
                }
            }
            Button(action: export) {
                SettingLabel("导出备份", symbol: "square.and.arrow.up", color: Theme.idealInk)
            }
            .disabled(passwordProblem != nil)
            Button {
                importing = true
            } label: {
                SettingLabel("导入备份", symbol: "square.and.arrow.down", color: Theme.idealInk)
            }
        } header: {
            Text("备份")
        } footer: {
            Text(usePassword
                ? "加密后只有输入密码才能导入，密码忘记将无法恢复。"
                : "导出为 JSON 文件，可以存到「文件」或用隔空投送发给自己。导入会合并到现有记录，重复的自动跳过。")
        }
        .listRowBackground(Theme.surface)
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
            if error != .wrongPassword { pendingImport = nil }
            message = error.localizedDescription
        } catch {
            pendingImport = nil
            message = "导入失败：\(error.localizedDescription)"
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    PalBuddy(face: .smile)
                        .frame(width: 40, height: 40)
                    Logotype(color: Theme.accent)
                        .frame(height: 22)
                }
                Text("你的记录只存在这台 iPhone 上，不用登录，谁也看不到。换手机前记得先导出备份哦。")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Theme.surface)
    }
}

/// Settings-style row label: symbol on a small round colored sticker.
struct SettingLabel: View {
    let title: String
    let symbol: String
    let color: Color
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 29

    init(_ title: String, symbol: String, color: Color) {
        self.title = title
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        Label {
            Text(title).foregroundStyle(Theme.ink)
        } icon: {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background(Sticker(color: color, edge: 0, lifted: false))
        }
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
