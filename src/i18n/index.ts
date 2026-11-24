import { useSyncExternalStore } from 'react'
import { en } from './en'
import { ja } from './ja'
import { zh, type Messages } from './zh'

export type { Messages }

export type Language = 'zh' | 'en' | 'ja'
export type LanguagePreference = 'system' | Language

export const LANGUAGES: readonly Language[] = ['zh', 'en', 'ja']

/** Each language is always shown in its own script, whatever the current UI language. */
export const LANGUAGE_NAMES: Record<Language, string> = { zh: '简体中文', en: 'English', ja: '日本語' }

const MESSAGES: Record<Language, Messages> = { zh, en, ja }

export const LANGUAGE_KEY = 'poopal.language'

/**
 * Picks the first supported language from the browser's preference list. Any Chinese variant
 * (including Traditional) maps to 简体中文, the closest one PooPal has; anything else falls back
 * to English.
 */
export function resolveSystemLanguage(preferred: readonly string[] | undefined): Language {
  for (const tag of preferred ?? []) {
    const base = tag.toLowerCase().split(/[-_]/)[0]
    if (base === 'zh' || base === 'en' || base === 'ja') return base
  }
  return 'en'
}

function systemLanguages(): readonly string[] {
  if (typeof navigator === 'undefined') return []
  return navigator.languages?.length ? navigator.languages : navigator.language ? [navigator.language] : []
}

function readPreference(): LanguagePreference {
  try {
    const raw = localStorage.getItem(LANGUAGE_KEY)
    return raw === 'zh' || raw === 'en' || raw === 'ja' ? raw : 'system'
  } catch {
    return 'system'
  }
}

interface LanguageState {
  preference: LanguagePreference
  language: Language
}

function stateFor(preference: LanguagePreference): LanguageState {
  return { preference, language: preference === 'system' ? resolveSystemLanguage(systemLanguages()) : preference }
}

let state: LanguageState = stateFor(readPreference())
const listeners = new Set<() => void>()

/** The current language's messages, for code outside React (formatting, notifications, backup errors). */
export function messages(): Messages {
  return MESSAGES[state.language]
}

export function currentLanguage(): Language {
  return state.language
}

export function messagesFor(language: Language): Messages {
  return MESSAGES[language]
}

export function setLanguagePreference(preference: LanguagePreference) {
  try {
    if (preference === 'system') localStorage.removeItem(LANGUAGE_KEY)
    else localStorage.setItem(LANGUAGE_KEY, preference)
  } catch {
    // Private mode or full storage: the choice just won't persist.
  }
  state = stateFor(preference)
  applyToDocument()
  listeners.forEach((l) => l())
}

function subscribe(listener: () => void) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

export function useLanguage(): LanguageState {
  return useSyncExternalStore(subscribe, () => state)
}

/** The current messages; re-renders the component when the language changes. */
export function useT(): Messages {
  return MESSAGES[useLanguage().language]
}

/** Keeps `<html lang>`, the description and the install manifest in step with the language. */
function applyToDocument() {
  if (typeof document === 'undefined') return
  const t = messages()
  document.documentElement.lang = t.htmlLang
  document.querySelector('meta[name="description"]')?.setAttribute('content', t.appDescription)
  const manifest = document.querySelector<HTMLLinkElement>('link[rel="manifest"]')
  if (manifest) {
    const file = state.language === 'zh' ? 'manifest.webmanifest' : `manifest.${state.language}.webmanifest`
    manifest.href = `${import.meta.env.BASE_URL}${file}`
  }
}

if (typeof window !== 'undefined') {
  applyToDocument()
  window.addEventListener('languagechange', () => {
    if (state.preference !== 'system') return
    state = stateFor('system')
    applyToDocument()
    listeners.forEach((l) => l())
  })
}
