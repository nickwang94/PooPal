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
import { APPEARANCES, setAppearance, updateReminders, useSettings } from '../data/settings'
import { LANGUAGE_NAMES, LANGUAGES, setLanguagePreference, useLanguage, useT, type LanguagePreference } from '../i18n'
import { BackupError, backupFileName, decodeBackup, encodeBackup, isEncryptedBackup, mergeSummary } from '../logic/backup'
import { pad } from '../logic/dates'
import { dailyComponents, INACTIVITY_HOUR, type ReminderSettings } from '../logic/reminders'

function errorText(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}

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
  const t = useT()
  return (
    <Sheet
      title={t.settings.title}
      labelledBy="settings-title"
      onClose={onClose}
      trailing={
        <button type="button" className="pill-button strong" onClick={onClose}>
          {t.settings.done}
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
  const { preference } = useLanguage()
  const t = useT()
  const appearanceOptions = APPEARANCES.map((value) => ({ value, title: t.settings.appearanceOptions[value] }))
  const languageOptions: { value: LanguagePreference; title: string }[] = [
    { value: 'system', title: t.settings.followSystem },
    ...LANGUAGES.map((value) => ({ value, title: LANGUAGE_NAMES[value] })),
  ]
  return (
    <Group header={t.settings.looks}>
      <div className="row setting-row stacked">
        <SettingLabel title={t.settings.appearance} icon="halfCircle" color="#7A4BA0" />
        <Segmented label={t.settings.appearance} value={appearance} options={appearanceOptions} onChange={setAppearance} />
      </div>
      <div className="row setting-row stacked">
        <SettingLabel title={t.settings.language} icon="globe" color="var(--loose-ink)" />
        <Segmented
          label={t.settings.language}
          value={preference}
          options={languageOptions}
          onChange={setLanguagePreference}
          className="language-picker"
        />
      </div>
    </Group>
  )
}

function RemindersSection() {
  const { reminders } = useSettings()
  const [permission, setPermission] = useState<NotificationSupport>(notificationSupport)
  const t = useT()

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
      header={t.settings.remindersHeader}
      footer={
        <>
          {reminders.inactivityEnabled && <p>{t.settings.inactivityFooter(reminders.inactivityDays, INACTIVITY_HOUR)}</p>}
          <p>{t.settings.webLimit}</p>
        </>
      }
    >
      <div className="row setting-row">
        <SettingLabel title={t.settings.inactivity} icon="bell" color="var(--dry-ink)" />
        <Toggle label={t.settings.inactivity} checked={reminders.inactivityEnabled} onChange={(v) => change({ inactivityEnabled: v })} />
      </div>
      {reminders.inactivityEnabled && (
        <div className="row setting-row indented">
          <span>{t.settings.inactivityDays}</span>
          <span className="stepper-wrap">
            <span className="muted num">{t.units.daysValue(reminders.inactivityDays)}</span>
            <Stepper
              label={t.settings.inactivityDays}
              value={reminders.inactivityDays}
              min={1}
              max={14}
              onChange={(v) => change({ inactivityDays: v })}
            />
          </span>
        </div>
      )}
      <div className="row setting-row">
        <SettingLabel title={t.settings.daily} icon="alarm" color="var(--loose-ink)" />
        <Toggle label={t.settings.daily} checked={reminders.dailyEnabled} onChange={(v) => change({ dailyEnabled: v })} />
      </div>
      {reminders.dailyEnabled && (
        <div className="row setting-row indented">
          <span>{t.settings.dailyTime}</span>
          <PickerPill
            type="time"
            label={t.settings.dailyTime}
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
          {t.settings.allowNotifications}
        </button>
      )}
      {anyOn && permission === 'denied' && <p className="row warning">{t.settings.notificationsDenied}</p>}
      {anyOn && permission === 'unsupported' && (
        <p className="row warning">
          {isStandalone() ? t.settings.notificationsUnsupported : t.settings.notificationsIos}
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
  const t = useT()
  const b = t.backup

  const problem = !usePassword
    ? null
    : password.length < 4
      ? b.passwordTooShort
      : password !== confirm
        ? b.passwordMismatch
        : null

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
      setStep({ kind: 'message', text: b.exportFailed(errorText(error)) })
    } finally {
      setBusy(false)
    }
  }

  const runImport = async (text: string, pw?: string) => {
    try {
      const file = await decodeBackup(text, pw)
      const plan = await importBackup(file)
      setStep({ kind: 'message', text: b.importDone(mergeSummary(plan)) })
    } catch (error) {
      if (error instanceof BackupError && error.code === 'wrongPassword') {
        setStep({ kind: 'password', text, error: BackupError.describe(error.code) })
      } else if (error instanceof BackupError) {
        setStep({ kind: 'message', text: BackupError.describe(error.code, error.version) })
      } else {
        setStep({ kind: 'message', text: b.importFailed(errorText(error)) })
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
      setStep({ kind: 'message', text: b.readFailed(errorText(error)) })
    } finally {
      if (fileInput.current) fileInput.current.value = ''
    }
  }

  const dismiss = useCallback(() => setStep({ kind: 'idle' }), [])

  return (
    <Group
      header={b.header}
      footer={<p>{usePassword ? b.footerEncrypted : b.footerPlain}</p>}
    >
      <div className="row setting-row">
        <SettingLabel title={b.usePassword} icon="lock" color="#7A6A7E" />
        <Toggle label={b.usePassword} checked={usePassword} onChange={setUsePassword} />
      </div>
      {usePassword && (
        <div className="row password-fields">
          <input
            type="password"
            autoComplete="new-password"
            placeholder={b.newPassword}
            aria-label={b.newPassword}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <input
            type="password"
            autoComplete="new-password"
            placeholder={b.repeatPassword}
            aria-label={b.repeatPassword}
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
          />
          {problem && password.length > 0 && <p className="warning">{problem}</p>}
        </div>
      )}
      <button type="button" className="row setting-row button-row" onClick={exportBackup} disabled={problem !== null || busy}>
        <SettingLabel title={busy ? b.preparing : b.export} icon="share" color="var(--ideal-ink)" />
      </button>
      {ready && (
        <button type="button" className="row link-row" onClick={() => void deliver(ready)}>
          {b.ready}
        </button>
      )}
      <button type="button" className="row setting-row button-row" onClick={() => fileInput.current?.click()}>
        <SettingLabel title={b.import} icon="download" color="var(--ideal-ink)" />
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
          title={b.passwordTitle}
          onDismiss={dismiss}
          actions={
            <>
              <button type="button" onClick={dismiss}>
                {b.cancel}
              </button>
              <button type="button" className="strong" onClick={() => void runImport(step.text, importPassword)}>
                {b.importAction}
              </button>
            </>
          }
        >
          <p>{step.error ?? b.passwordPrompt}</p>
          <input
            type="password"
            autoComplete="current-password"
            aria-label={b.passwordLabel}
            placeholder={b.passwordLabel}
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
              {b.ok}
            </button>
          }
        />
      )}
    </Group>
  )
}

function AboutSection() {
  const t = useT()
  return (
    <div className="form-group about">
      <div className="about-brand">
        <PalBuddy face="smile" size={40} />
        <Logotype height={22} />
      </div>
      <p>{t.about.privacy}</p>
      {!isStandalone() && <p>{t.about.install}</p>}
      {isDemo && <p className="warning">{t.about.demo}</p>}
    </div>
  )
}
