import { useCallback, useRef, useState, type ReactNode } from 'react'
import { Icon, type IconName } from '../components/Icons'
import { Logotype } from '../components/Logotype'
import { PalBuddy } from '../components/PalBuddy'
import { AlertDialog, PickerPill, Segmented, Sheet, Stepper, Toggle } from '../components/ui'
import { allBackupEntries, importBackup, isDemo } from '../data/entries'
import {
  checkReminders,
  isStandalone,
  notificationSupport,
  requestNotificationPermission,
  type NotificationSupport,
} from '../data/notifications'
import { APPEARANCE_OPTIONS, setAppearance, updateReminders, useSettings } from '../data/settings'
import { BackupError, backupFileName, decodeBackup, encodeBackup, isEncryptedBackup, mergeSummary } from '../logic/backup'
import { pad } from '../logic/dates'
import { dailyComponents, INACTIVITY_HOUR, type ReminderSettings } from '../logic/reminders'

function SettingLabel({ title, icon, color }: { title: string; icon: IconName; color: string }) {
  return (
    <span className="setting-label">
      <span className="setting-icon" style={{ background: color }}>
        <Icon name={icon} size={17} />
      </span>
      <span>{title}</span>
    </span>
  )
}

function Group({ header, footer, children }: { header: string; footer?: ReactNode; children: ReactNode }) {
  return (
    <section className="settings-group">
      <h2 className="form-header">{header}</h2>
      <div className="form-group">{children}</div>
      {footer && <div className="form-footer">{footer}</div>}
    </section>
  )
}

export function Settings({ onClose }: { onClose: () => void }) {
  return (
    <Sheet
      title="设置"
      onClose={onClose}
      trailing={
        <button type="button" className="pill-button strong" onClick={onClose}>
          完成
        </button>
      }
    >
      <AppearanceSection />
      <RemindersSection />
      <BackupSection />
      <AboutSection />
    </Sheet>
  )
}

function AppearanceSection() {
  const { appearance } = useSettings()
  return (
    <Group header="看起来">
      <div className="row setting-row stacked">
        <SettingLabel title="外观" icon="halfCircle" color="#7A4BA0" />
        <Segmented label="外观" value={appearance} options={APPEARANCE_OPTIONS} onChange={setAppearance} />
      </div>
    </Group>
  )
}

function RemindersSection() {
  const { reminders } = useSettings()
  const [permission, setPermission] = useState<NotificationSupport>(notificationSupport)

  const change = async (patch: Partial<ReminderSettings>) => {
    updateReminders(patch)
    const turningOn = patch.inactivityEnabled === true || patch.dailyEnabled === true
    if (turningOn && notificationSupport() === 'default') {
      setPermission(await requestNotificationPermission())
    }
    void checkReminders()
  }

  const askPermission = async () => {
    setPermission(await requestNotificationPermission())
    void checkReminders()
  }

  const { hour, minute } = dailyComponents(reminders.dailyMinutes)
  const anyOn = reminders.inactivityEnabled || reminders.dailyEnabled

  return (
    <Group
      header="小提醒"
      footer={
        <>
          {reminders.inactivityEnabled && (
            <p>
              超过 {reminders.inactivityDays} 天没来的话，上午 {INACTIVITY_HOUR} 点轻轻提醒你。
            </p>
          )}
          <p>网页版只能在 PooPal 开着或刚切到后台时发提醒；完全关掉后，会在下次打开时补上。</p>
        </>
      }
    >
      <div className="row setting-row">
        <SettingLabel title="太久没来时提醒我" icon="bell" color="var(--dry-ink)" />
        <Toggle label="太久没来时提醒我" checked={reminders.inactivityEnabled} onChange={(v) => change({ inactivityEnabled: v })} />
      </div>
      {reminders.inactivityEnabled && (
        <div className="row setting-row indented">
          <span>超过几天算太久</span>
          <span className="stepper-wrap">
            <span className="muted num">{reminders.inactivityDays} 天</span>
            <Stepper
              label="超过几天算太久"
              value={reminders.inactivityDays}
              min={1}
              max={14}
              onChange={(v) => change({ inactivityDays: v })}
            />
          </span>
        </div>
      )}
      <div className="row setting-row">
        <SettingLabel title="每天提醒我记一下" icon="alarm" color="var(--loose-ink)" />
        <Toggle label="每天提醒我记一下" checked={reminders.dailyEnabled} onChange={(v) => change({ dailyEnabled: v })} />
      </div>
      {reminders.dailyEnabled && (
        <div className="row setting-row indented">
          <span>提醒时间</span>
          <PickerPill
            type="time"
            label="提醒时间"
            value={`${pad(hour)}:${pad(minute)}`}
            display={`${pad(hour)}:${pad(minute)}`}
            onChange={(value) => {
              const [h, m] = value.split(':').map(Number)
              if (!Number.isNaN(h) && !Number.isNaN(m)) void change({ dailyMinutes: h * 60 + m })
            }}
          />
        </div>
      )}
      {anyOn && permission === 'default' && (
        <button type="button" className="row link-row" onClick={askPermission}>
          允许 PooPal 发通知
        </button>
      )}
      {anyOn && permission === 'denied' && <p className="row warning">通知权限已关闭。请在浏览器或系统设置里允许 PooPal 发通知。</p>}
      {anyOn && permission === 'unsupported' && (
        <p className="row warning">
          {isStandalone()
            ? '这个浏览器不支持网页通知。'
            : 'iPhone 上要先在 Safari 点「分享 › 添加到主屏幕」，从主屏幕打开后才能开启提醒（需要 iOS 16.4 及以上）。'}
        </p>
      )}
    </Group>
  )
}

type ImportStep = { kind: 'idle' } | { kind: 'password'; text: string; error?: string } | { kind: 'message'; text: string }

function BackupSection() {
  const [usePassword, setUsePassword] = useState(false)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [busy, setBusy] = useState(false)
  const [ready, setReady] = useState<File | null>(null)
  const [step, setStep] = useState<ImportStep>({ kind: 'idle' })
  const [importPassword, setImportPassword] = useState('')
  const fileInput = useRef<HTMLInputElement>(null)

  const problem = !usePassword ? null : password.length < 4 ? '密码至少 4 位' : password !== confirm ? '两次输入的密码不一致' : null

  const deliver = async (file: File) => {
    if (navigator.canShare?.({ files: [file] })) {
      try {
        await navigator.share({ files: [file], title: file.name })
        setReady(null)
        return
      } catch (error) {
        if (error instanceof DOMException && error.name === 'AbortError') return
        // Share lost the tap's user activation after the slow encryption: offer a second tap.
        if (error instanceof DOMException && error.name === 'NotAllowedError') {
          setReady(file)
          return
        }
      }
    }
    const url = URL.createObjectURL(file)
    const a = document.createElement('a')
    a.href = url
    a.download = file.name
    document.body.append(a)
    a.click()
    a.remove()
    setTimeout(() => URL.revokeObjectURL(url), 10_000)
    setReady(null)
  }

  const exportBackup = async () => {
    if (problem || busy) return
    setBusy(true)
    try {
      const entries = await allBackupEntries()
      const encrypted = usePassword && password.length > 0
      const text = await encodeBackup(entries, { password: encrypted ? password : null })
      const file = new File([text], backupFileName(Date.now(), encrypted), { type: 'application/json' })
      await deliver(file)
    } catch (error) {
      setStep({ kind: 'message', text: `导出失败：${error instanceof Error ? error.message : String(error)}` })
    } finally {
      setBusy(false)
    }
  }

  const runImport = async (text: string, pw?: string) => {
    try {
      const file = await decodeBackup(text, pw)
      const plan = await importBackup(file)
      setStep({ kind: 'message', text: `导入完成：${mergeSummary(plan)}` })
    } catch (error) {
      if (error instanceof BackupError && error.code === 'wrongPassword') {
        setStep({ kind: 'password', text, error: error.message })
      } else {
        setStep({ kind: 'message', text: error instanceof Error ? error.message : `导入失败：${String(error)}` })
      }
    }
  }

  const picked = async (file: File | undefined) => {
    if (!file) return
    try {
      const text = await file.text()
      if (isEncryptedBackup(text)) {
        setImportPassword('')
        setStep({ kind: 'password', text })
      } else {
        await runImport(text)
      }
    } catch (error) {
      setStep({ kind: 'message', text: `读取文件失败：${error instanceof Error ? error.message : String(error)}` })
    } finally {
      if (fileInput.current) fileInput.current.value = ''
    }
  }

  const dismiss = useCallback(() => setStep({ kind: 'idle' }), [])

  return (
    <Group
      header="备份"
      footer={
        <p>
          {usePassword
            ? '加密后只有输入密码才能导入，密码忘记将无法恢复。'
            : '导出为 JSON 文件，可以存到「文件」或发给自己。导入会合并到现有记录，重复的自动跳过。和 iOS 版 PooPal 的备份互通。'}
        </p>
      }
    >
      <div className="row setting-row">
        <SettingLabel title="给备份加个密码" icon="lock" color="#7A6A7E" />
        <Toggle label="给备份加个密码" checked={usePassword} onChange={setUsePassword} />
      </div>
      {usePassword && (
        <div className="row password-fields">
          <input
            type="password"
            autoComplete="new-password"
            placeholder="设置密码（至少 4 位）"
            aria-label="设置密码（至少 4 位）"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <input
            type="password"
            autoComplete="new-password"
            placeholder="再输入一次"
            aria-label="再输入一次"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
          />
          {problem && password.length > 0 && <p className="warning">{problem}</p>}
        </div>
      )}
      <button type="button" className="row setting-row button-row" onClick={exportBackup} disabled={problem !== null || busy}>
        <SettingLabel title={busy ? '正在准备…' : '导出备份'} icon="share" color="var(--ideal-ink)" />
      </button>
      {ready && (
        <button type="button" className="row link-row" onClick={() => void deliver(ready)}>
          备份准备好了，点这里保存
        </button>
      )}
      <button type="button" className="row setting-row button-row" onClick={() => fileInput.current?.click()}>
        <SettingLabel title="导入备份" icon="download" color="var(--ideal-ink)" />
      </button>
      <input
        ref={fileInput}
        type="file"
        accept=".json,application/json"
        hidden
        onChange={(e) => void picked(e.target.files?.[0])}
      />

      {step.kind === 'password' && (
        <AlertDialog
          title="这个备份设置了密码"
          onDismiss={dismiss}
          actions={
            <>
              <button type="button" onClick={dismiss}>
                取消
              </button>
              <button type="button" className="strong" onClick={() => void runImport(step.text, importPassword)}>
                导入
              </button>
            </>
          }
        >
          <p>{step.error ?? '请输入导出时设置的密码。'}</p>
          <input
            type="password"
            autoComplete="current-password"
            aria-label="备份密码"
            placeholder="备份密码"
            value={importPassword}
            onChange={(e) => setImportPassword(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && void runImport(step.text, importPassword)}
          />
        </AlertDialog>
      )}
      {step.kind === 'message' && (
        <AlertDialog
          title={step.text}
          onDismiss={dismiss}
          actions={
            <button type="button" className="strong" onClick={dismiss}>
              好
            </button>
          }
        />
      )}
    </Group>
  )
}

function AboutSection() {
  return (
    <div className="form-group about">
      <div className="about-brand">
        <PalBuddy face="smile" size={40} />
        <Logotype height={22} />
      </div>
      <p>
        你的记录只存在这个浏览器里，不用登录，谁也看不到。换手机、换浏览器或清理网站数据前，记得先导出备份哦。
      </p>
      {!isStandalone() && <p>在 iPhone 的 Safari 里点「分享 › 添加到主屏幕」，用起来就像 App 一样，没网也能打开。</p>}
      {isDemo && <p className="warning">现在看的是示例数据，改动不会保存到你的记录里。</p>}
    </div>
  )
}
