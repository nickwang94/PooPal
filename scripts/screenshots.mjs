// Takes light and dark screenshots of every screen with sample data (`?demo`, which never touches
// real records). Needs a running server: `npm run build && npx vite preview --port 4173`, then
// `node scripts/screenshots.mjs [baseUrl] [outDir]`. Uses Playwright's Chromium, or set CHROME_PATH.
import { mkdir } from 'node:fs/promises'
import { chromium } from 'playwright'

const baseUrl = process.argv[2] ?? 'http://localhost:4173/'
const outDir = process.argv[3] ?? 'screenshots'
const prefix = process.env.SHOT_PREFIX ?? ''

await mkdir(outDir, { recursive: true })
const browser = await chromium.launch({
  args: ['--lang=zh-CN'],
  ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}),
})

for (const appearance of ['light', 'dark']) {
  const context = await browser.newContext({
    viewport: { width: 393, height: 852 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    locale: 'zh-CN',
    timezoneId: 'Asia/Shanghai',
    colorScheme: appearance,
  })
  await context.addInitScript((value) => localStorage.setItem('poopal.appearance', value), appearance)
  const page = await context.newPage()
  page.on('pageerror', (error) => {
    console.error(error)
    process.exitCode = 1
  })
  const shot = async (name) => {
    await page.waitForTimeout(450)
    const path = `${outDir}/${prefix}${appearance}-${name}.png`
    await page.screenshot({ path })
    console.log(`wrote ${path}`)
  }
  const url = (hash) => `${baseUrl}?demo${hash}`

  await page.goto(url('#/'))
  await page.waitForSelector('.log-sticker')
  await shot('home')
  await page.locator('text=最近怎么样').scrollIntoViewIfNeeded()
  await page.evaluate(() => scrollBy(0, 200))
  await shot('home-stats')

  await page.locator('.entry-row').first().click()
  await page.waitForSelector('.sheet')
  await shot('edit')
  await page.getByRole('button', { name: '取消' }).click()

  await page.evaluate(() => scrollTo(0, 0))
  await page.getByRole('button', { name: '忘了记？补一条' }).click()
  await page.getByRole('radio', { name: '3 型 裂纹条' }).click()
  await shot('add-entry')
  await page.getByRole('button', { name: '取消' }).click()

  await page.getByRole('button', { name: '设置' }).click()
  await page.waitForSelector('.sheet')
  await shot('settings')
  await page.getByRole('button', { name: '完成' }).click()

  await page.getByRole('link', { name: '贴纸本' }).click()
  await page.waitForSelector('.month-mosaic')
  await shot('history-calendar')
  await page.getByRole('radio', { name: '列表' }).click()
  await shot('history-list')
  await page.getByRole('radio', { name: '趋势' }).click()
  await page.waitForSelector('.bar-chart')
  await shot('trends')
  await page.locator('.all-numbers summary').click()
  await page.locator('.all-numbers .panel').scrollIntoViewIfNeeded()
  await shot('trends-numbers')

  await context.close()
}

await browser.close()
