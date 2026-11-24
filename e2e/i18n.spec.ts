import { expect, test, type Page } from '@playwright/test'

/** Han, kana and CJK punctuation: none of it should show up in the English UI. */
const CJK = /[\u3000-\u303f\u3040-\u30ff\u4e00-\u9fff\uff00-\uffef]/

/** Language names are always written in their own script, so the picker is excluded. */
async function visibleCjk(page: Page): Promise<string[]> {
  const text = await page.evaluate(() => {
    const clone = document.body.cloneNode(true) as HTMLElement
    clone.querySelectorAll('.language-picker, noscript, script, style').forEach((el) => el.remove())
    const labels = [...document.querySelectorAll('[aria-label], [placeholder], [aria-description]')]
      .filter((el) => !el.closest('.language-picker'))
      .flatMap((el) => ['aria-label', 'placeholder', 'aria-description'].map((a) => el.getAttribute(a) ?? ''))
    return [clone.innerText, ...labels].join('\n')
  })
  return text.split('\n').filter((line) => CJK.test(line))
}

test.describe('follows the system language by default', () => {
  test.describe('Japanese browser', () => {
    test.use({ locale: 'ja-JP' })
    test('shows Japanese', async ({ page }) => {
      await page.goto('/?demo#/')
      await expect(page.getByRole('button', { name: /^記録する/ })).toBeVisible()
      await expect(page.locator('html')).toHaveAttribute('lang', 'ja')
      await expect(page.getByRole('link', { name: 'シール帳' })).toBeVisible()
    })
  })

  test.describe('Chinese browser', () => {
    test.use({ locale: 'zh-CN' })
    test('shows Simplified Chinese', async ({ page }) => {
      await page.goto('/?demo#/')
      await expect(page.getByRole('button', { name: /^记一下/ })).toBeVisible()
      await expect(page.locator('html')).toHaveAttribute('lang', 'zh-CN')
    })
  })

  test.describe('Traditional Chinese browser', () => {
    test.use({ locale: 'zh-TW' })
    test('falls back to Simplified Chinese', async ({ page }) => {
      await page.goto('/?demo#/')
      await expect(page.getByRole('button', { name: /^记一下/ })).toBeVisible()
    })
  })

  test.describe('unsupported browser language', () => {
    test.use({ locale: 'fr-FR' })
    test('falls back to English', async ({ page }) => {
      await page.goto('/?demo#/')
      await expect(page.getByRole('button', { name: /^Log it/ })).toBeVisible()
      await expect(page.locator('html')).toHaveAttribute('lang', 'en')
    })
  })
})

test.describe('language setting', () => {
  test.use({ locale: 'zh-CN' })

  test('switches instantly, persists, and can go back to the system language', async ({ page }) => {
    await page.goto('/?demo#/')
    await page.getByRole('button', { name: '设置' }).first().click()
    const picker = page.getByRole('radiogroup', { name: '语言' })
    await expect(picker.getByRole('radio', { name: '跟随系统' })).toHaveAttribute('aria-checked', 'true')

    await picker.getByRole('radio', { name: 'English' }).click()
    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible()
    await expect(page.getByRole('radiogroup', { name: 'Language' }).getByRole('radio', { name: 'English' })).toHaveAttribute(
      'aria-checked',
      'true',
    )
    expect(await page.evaluate(() => localStorage.getItem('poopal.language'))).toBe('en')

    await page.reload()
    await expect(page.getByRole('button', { name: /^Log it/ })).toBeVisible()

    await page.getByRole('button', { name: 'Settings' }).first().click()
    await page.getByRole('radiogroup', { name: 'Language' }).getByRole('radio', { name: '日本語' }).click()
    await expect(page.getByRole('heading', { name: '設定' })).toBeVisible()
    await expect(page.getByText('バックアップを書き出す')).toBeVisible()

    await page.getByRole('radiogroup', { name: '言語' }).getByRole('radio', { name: 'システム' }).click()
    await expect(page.getByRole('heading', { name: '设置' })).toBeVisible()
    expect(await page.evaluate(() => localStorage.getItem('poopal.language'))).toBeNull()
  })

  test('points the install manifest at the chosen language', async ({ page }) => {
    await page.goto('/?demo#/')
    const manifest = page.locator('link[rel="manifest"]')
    await expect(manifest).toHaveAttribute('href', '/manifest.webmanifest')
    await page.getByRole('button', { name: '设置' }).first().click()
    await page.getByRole('radiogroup', { name: '语言' }).getByRole('radio', { name: '日本語' }).click()
    await expect(manifest).toHaveAttribute('href', '/manifest.ja.webmanifest')
    const response = await page.request.get('/manifest.ja.webmanifest')
    expect((await response.json()).lang).toBe('ja')
  })
})

test.describe('English UI has no untranslated text', () => {
  test.use({ locale: 'en-US' })

  test('on every screen', async ({ page }) => {
    const errors: Error[] = []
    page.on('pageerror', (error) => errors.push(error))
    await page.goto('/?demo#/')
    await expect(page.getByRole('button', { name: /^Log it/ })).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])

    await page.locator('.entry-row').first().click()
    await expect(page.getByRole('heading', { name: 'Edit' })).toBeVisible()
    await page.getByRole('radio', { name: 'Type 3 Cracked log' }).click()
    await expect(page.getByText('Ideal · A log with a few cracks, pretty good')).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])
    await page.getByRole('button', { name: 'Delete this entry' }).click()
    await expect(page.getByText('Once it’s deleted, it’s gone for good')).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])
    await page.getByRole('button', { name: 'Cancel' }).last().click()
    await page.getByRole('button', { name: 'Cancel' }).click()

    await page.getByRole('button', { name: 'Forgot one? Add it' }).click()
    await expect(page.getByRole('heading', { name: 'Add one' })).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])
    await page.getByRole('button', { name: 'Cancel' }).click()

    await page.getByRole('button', { name: 'Settings' }).first().click()
    await page.getByRole('switch', { name: 'Daily reminder to log' }).click()
    await page.getByRole('switch', { name: 'Password-protect backups' }).click()
    await page.getByRole('textbox', { name: 'Password (at least 4 characters)' }).fill('ab')
    await expect(page.getByText('Use at least 4 characters')).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])
    await page.getByRole('button', { name: 'Done' }).click()

    await page.getByRole('link', { name: 'Stickers' }).click()
    await expect(page.getByRole('heading', { name: 'My sticker book' })).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])
    await page.getByRole('radio', { name: 'List' }).click()
    expect(await visibleCjk(page)).toEqual([])
    await page.getByRole('radio', { name: 'Trends' }).click()
    await page.getByRole('radio', { name: 'Monthly' }).click()
    await page.locator('.all-numbers summary').click()
    await expect(page.getByText('Logged in total')).toBeVisible()
    expect(await visibleCjk(page)).toEqual([])
    expect(errors).toEqual([])
  })
})

test.describe('backup dialogs', () => {
  test.use({ locale: 'ja-JP' })

  test('report import results and errors in the current language', async ({ page }) => {
    await page.goto('/?demo#/')
    await page.getByRole('button', { name: '設定' }).first().click()
    const chooser = page.waitForEvent('filechooser')
    await page.getByRole('button', { name: 'バックアップを読み込む' }).click()
    await (await chooser).setFiles({ name: 'broken.json', mimeType: 'application/json', buffer: Buffer.from('{"nope":1}') })
    await expect(page.getByRole('alertdialog', { name: /PooPal のバックアップファイルではない/ })).toBeVisible()
    await page.getByRole('button', { name: 'OK' }).click()

    const backup = JSON.stringify({
      app: 'PooPal',
      version: 1,
      exportedAt: '2026-01-02T03:04:05Z',
      entries: [{ timestamp: '2026-01-01T01:00:00Z', bristolType: 4 }],
    })
    const chooser2 = page.waitForEvent('filechooser')
    await page.getByRole('button', { name: 'バックアップを読み込む' }).click()
    await (await chooser2).setFiles({ name: 'ok.json', mimeType: 'application/json', buffer: Buffer.from(backup) })
    await expect(page.getByRole('alertdialog', { name: '読み込み完了：1件を追加、重複 0件をスキップ' })).toBeVisible()
  })
})
