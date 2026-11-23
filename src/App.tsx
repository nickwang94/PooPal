import { useCallback, useEffect, useRef, useState } from 'react'
import { Icon } from './components/Icons'
import { addEntry, deleteEntry, makeEntry, useEntries, type Entry } from './data/entries'
import { checkReminders } from './data/notifications'
import { prefersReducedMotion, useApplyAppearance, useSettings } from './data/settings'
import { DateText } from './logic/dates'
import { EntryEditor } from './screens/EntryEditor'
import { History, type HistoryMode } from './screens/History'
import { Home } from './screens/Home'
import { Settings } from './screens/Settings'

type Route = { tab: 'home' } | { tab: 'history'; mode: HistoryMode }

function parseHash(hash: string): Route {
  const [, tab, mode] = hash.replace(/^#/, '').split('/')
  if (tab === 'history') {
    return { tab: 'history', mode: mode === 'list' || mode === 'trends' ? mode : 'calendar' }
  }
  return { tab: 'home' }
}

function routeHash(route: Route): string {
  return route.tab === 'home' ? '#/' : `#/history/${route.mode}`
}

type SheetState = { kind: 'add' } | { kind: 'edit'; id: string } | { kind: 'settings' } | null

function useNow(): number {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    const tick = () => setNow(Date.now())
    const id = setInterval(tick, 30_000)
    document.addEventListener('visibilitychange', tick)
    return () => {
      clearInterval(id)
      document.removeEventListener('visibilitychange', tick)
    }
  }, [])
  return now
}

export function App() {
  const { entries, loaded, error } = useEntries()
  const { appearance, reminders } = useSettings()
  useApplyAppearance(appearance)
  // Entries are saved with the real clock, so the ticking clock must never lag behind the newest one.
  const now = Math.max(useNow(), entries[0]?.timestamp ?? 0)
  const [route, setRoute] = useState<Route>(() => parseHash(location.hash))
  const [sheet, setSheet] = useState<SheetState>(null)
  const [logCount, setLogCount] = useState(0)
  const [lastLogged, setLastLogged] = useState<Entry | null>(null)
  const toastTimer = useRef<ReturnType<typeof setTimeout>>(undefined)

  useEffect(() => {
    const onHash = () => setRoute(parseHash(location.hash))
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [])

  useEffect(() => {
    if (loaded) void checkReminders()
  }, [loaded, entries, reminders, now])

  const navigate = (next: Route) => {
    history.replaceState(null, '', routeHash(next))
    setRoute(next)
    window.scrollTo({ top: 0 })
  }

  const logNow = async () => {
    const entry = makeEntry(Date.now())
    await addEntry(entry)
    setLogCount((c) => c + 1)
    setLastLogged(entry)
    if (!prefersReducedMotion()) navigator.vibrate?.(12)
    clearTimeout(toastTimer.current)
    toastTimer.current = setTimeout(() => setLastLogged(null), 6000)
  }

  const undo = async () => {
    if (!lastLogged) return
    clearTimeout(toastTimer.current)
    await deleteEntry(lastLogged.id)
    setLastLogged(null)
  }

  const closeSheet = useCallback(() => setSheet(null), [])
  const edit = (entry: Entry) => setSheet({ kind: 'edit', id: entry.id })
  const editing = sheet?.kind === 'edit' ? entries.find((e) => e.id === sheet.id) : undefined

  return (
    <div className="app" aria-busy={!loaded}>
      <main className="content">
        {error ? (
          <div className="empty-state">
            <h2>打不开本地数据库</h2>
            <p>浏览器可能处于无痕模式，或禁止了网站存储。PooPal 需要 IndexedDB 才能保存记录。</p>
            <p className="muted">{error}</p>
          </div>
        ) : !loaded ? null : route.tab === 'home' ? (
          <Home
            entries={entries}
            now={now}
            logCount={logCount}
            onLog={logNow}
            onAdd={() => setSheet({ kind: 'add' })}
            onEdit={edit}
            onSettings={() => setSheet({ kind: 'settings' })}
          />
        ) : (
          <History
            entries={entries}
            now={now}
            mode={route.mode}
            onModeChange={(mode) => navigate({ tab: 'history', mode })}
            onAdd={() => setSheet({ kind: 'add' })}
            onEdit={edit}
          />
        )}
      </main>

      {lastLogged && route.tab === 'home' && (
        <div className="toast" role="status">
          <Icon name="seal" size={24} className="toast-icon" />
          <span className="toast-text">记好啦 · {DateText.time(lastLogged.timestamp)}</span>
          <button
            type="button"
            className="toast-action"
            onClick={() => {
              setSheet({ kind: 'edit', id: lastLogged.id })
              setLastLogged(null)
            }}
          >
            加点细节
          </button>
          <button type="button" className="toast-action danger" onClick={undo}>
            撤销
          </button>
        </div>
      )}

      <nav className="tab-bar glass" aria-label="主导航">
        <a
          href="#/"
          className={route.tab === 'home' ? 'active' : ''}
          aria-current={route.tab === 'home' ? 'page' : undefined}
          onClick={(e) => {
            e.preventDefault()
            navigate({ tab: 'home' })
          }}
        >
          <Icon name="home" size={24} />
          <span>今天</span>
        </a>
        <a
          href="#/history/calendar"
          className={route.tab === 'history' ? 'active' : ''}
          aria-current={route.tab === 'history' ? 'page' : undefined}
          onClick={(e) => {
            e.preventDefault()
            navigate({ tab: 'history', mode: route.tab === 'history' ? route.mode : 'calendar' })
          }}
        >
          <Icon name="grid" size={24} />
          <span>贴纸本</span>
        </a>
      </nav>

      {sheet?.kind === 'add' && <EntryEditor onClose={closeSheet} />}
      {sheet?.kind === 'edit' && editing && <EntryEditor key={editing.id} entry={editing} onClose={closeSheet} />}
      {sheet?.kind === 'settings' && <Settings onClose={closeSheet} />}
    </div>
  )
}
