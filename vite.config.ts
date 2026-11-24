import react from '@vitejs/plugin-react'
import type { Plugin } from 'vite'
import { VitePWA, type ManifestOptions } from 'vite-plugin-pwa'
import { defineConfig } from 'vitest/config'

// Serve from a sub-path (e.g. https://example.com/poopal/) with BASE_PATH=/poopal/ at build time.
const base = process.env.BASE_PATH ?? '/'

const manifest: Partial<ManifestOptions> = {
  id: base,
  name: 'PooPal 便便小伙伴',
  short_name: 'PooPal',
  description: '记录便便的小贴纸手帐：一键记录、布里斯托分型、日历和趋势。数据只存在这台设备上。',
  lang: 'zh-CN',
  dir: 'ltr',
  start_url: base,
  scope: base,
  display: 'standalone',
  orientation: 'any',
  background_color: '#FFF8F0',
  theme_color: '#FFF8F0',
  categories: ['health', 'lifestyle'],
  icons: [
    { src: 'icons/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
    { src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
    { src: 'icons/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
  ],
}

// A manifest has a single language, so the app points <link rel="manifest"> at one of these when
// the UI language is not Chinese (see src/i18n/index.ts).
const translatedManifests: Record<string, Partial<ManifestOptions>> = {
  en: {
    name: 'PooPal: Poop Pal',
    description: 'A little sticker journal for your poops: one-tap logging, Bristol types, calendar and trends. Data stays on this device.',
    lang: 'en',
  },
  ja: {
    name: 'PooPal うんちの相棒',
    description: 'うんちを記録するシール手帳：ワンタップ記録、ブリストル分類、カレンダーと傾向。データはこの端末だけに保存されます。',
    lang: 'ja',
  },
}

function translatedManifestsPlugin(): Plugin {
  return {
    name: 'poopal-translated-manifests',
    apply: 'build',
    generateBundle() {
      for (const [lang, overrides] of Object.entries(translatedManifests)) {
        this.emitFile({
          type: 'asset',
          fileName: `manifest.${lang}.webmanifest`,
          source: JSON.stringify({ ...manifest, ...overrides }),
        })
      }
    },
  }
}

export default defineConfig({
  base,
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      injectRegister: null,
      includeAssets: ['icons/apple-touch-icon.png', 'icons/favicon.svg'],
      manifest,
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,woff2}'],
        navigateFallback: 'index.html',
        cleanupOutdatedCaches: true,
      },
    }),
    translatedManifestsPlugin(),
  ],
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
    setupFiles: ['src/test/setup.ts'],
  },
})
