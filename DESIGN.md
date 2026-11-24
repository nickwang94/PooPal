---
name: PooPal
description: A sticker habit journal for your gut; every visit is a round sticker, and a small buddy keeps you company.
colors:
  ground: "#FFF8F0"
  ground-dark: "#1C1620"
  surface: "#FFFFFF"
  surface-dark: "#2A2230"
  surface-sunk: "#F6ECE1"
  surface-sunk-dark: "#352B3B"
  line: "#EDE1D5"
  line-dark: "#41364A"
  ink: "#3A2A3E"
  ink-dark: "#F7EEE6"
  ink-soft: "#7A6A7E"
  ink-soft-dark: "#B9A9BD"
  accent: "#7A4BA0"
  accent-dark: "#C59BEA"
  accent-soft: "#D6C3E8"
  accent-soft-dark: "#5A4470"
  accent-pale: "#F1E8F8"
  accent-pale-dark: "#3A2E48"
  on-accent: "#FFFFFF"
  on-accent-dark: "#241A2B"
  sunny: "#FFC83D"
  sunny-dark: "#F5B83A"
  sunny-deep: "#F6AE22"
  sunny-deep-dark: "#D99A22"
  on-sunny: "#3A2440"
  day-1: "#FFE7A6"
  day-1-dark: "#EBD7A2"
  day-2: "#FFC83D"
  day-2-dark: "#F2B53A"
  day-3: "#F29A2E"
  day-3-dark: "#EE8F2A"
  day-ink: "#3A2440"
  dry: "#D9711F"
  dry-dark: "#F5A25A"
  dry-pale: "#FDE6D0"
  dry-pale-dark: "#F2D6BC"
  ideal: "#3B8D5A"
  ideal-dark: "#7CCB95"
  ideal-pale: "#DDF1E2"
  ideal-pale-dark: "#CBE6D3"
  loose: "#3A7FC6"
  loose-dark: "#86BDF2"
  loose-pale: "#DCEAF9"
  loose-pale-dark: "#CCDDF1"
  dry-ink: "#C2631A"
  ideal-ink: "#2F7A4B"
  loose-ink: "#2F6DB0"
  alert: "#D23F5C"
  alert-dark: "#FF8098"
  blush: "#FF8FA3"
  sticker-edge: "#FFFFFF"
  sticker-edge-dark: "#EDE3EA"
typography:
  count:
    fontFamily: "SF Pro Rounded (system), monospaced digits"
    fontSize: "largeTitle"
    fontWeight: 700
  action:
    fontFamily: "SF Pro Rounded (system)"
    fontSize: "title"
    fontWeight: 800
  section-title:
    fontFamily: "SF Pro Rounded (system)"
    fontSize: "title3"
    fontWeight: 700
  body:
    fontFamily: "SF Pro Rounded (system)"
    fontSize: "body"
    fontWeight: 400
  caption:
    fontFamily: "SF Pro Rounded (system)"
    fontSize: "caption / caption2"
    fontWeight: 500
rounded:
  settings-icon: "50%"
  day-sticker: "50%"
  picker-sticker: "18px"
  panel: "24px"
  log-sticker: "32px"
  button: "capsule"
spacing:
  screen-edge: "20px"
  section-gap: "30px"
  sticker-gap: "6px"
  panel-row: "16px"
components:
  log-sticker-button:
    backgroundColor: "{colors.sunny}"
    textColor: "{colors.on-sunny}"
    rounded: "{rounded.log-sticker}"
    padding: "22px"
    height: "180px"
  secondary-button:
    backgroundColor: "{colors.accent-pale}"
    textColor: "{colors.accent}"
    rounded: "{rounded.button}"
  panel:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.panel}"
  day-sticker-0:
    backgroundColor: "{colors.surface-sunk}"
    textColor: "{colors.ink-soft}"
    rounded: "{rounded.day-sticker}"
  day-sticker-1:
    backgroundColor: "{colors.day-1}"
    textColor: "{colors.day-ink}"
    rounded: "{rounded.day-sticker}"
  day-sticker-2:
    backgroundColor: "{colors.day-2}"
    textColor: "{colors.day-ink}"
    rounded: "{rounded.day-sticker}"
  day-sticker-3:
    backgroundColor: "{colors.day-3}"
    textColor: "{colors.day-ink}"
    rounded: "{rounded.day-sticker}"
  bristol-sticker:
    backgroundColor: "{colors.ideal-pale}"
    textColor: "{colors.ink}"
    rounded: "{rounded.picker-sticker}"
    height: "84px"
  pal-buddy:
    backgroundColor: "{colors.sunny}"
    textColor: "{colors.on-sunny}"
    size: "76px"
---

# PooPal design system

Source of truth:
- `src/styles.css`: tokens as CSS custom properties, stickers, panels, controls.
- `src/logic/logotype.ts` + `src/components/Logotype.tsx`: the wordmark (also drives the app icon via `scripts/render-icons.mjs`).
- `src/components/PalBuddy.tsx`: the buddy character.
- `src/components/Bristol.tsx`, `src/components/colors.ts`: Bristol glyphs, picker and state colors.

Every color is a light/dark pair: `:root` holds the light half and `:root[data-theme='dark']` the dark half. The `-dark` keys above are the dark halves of the same token, not separate tokens.

Web notes: point sizes below map 1:1 to CSS px. "SF Pro Rounded" is `ui-rounded` on Apple devices with a bundled Nunito (Latin only) fallback elsewhere; Chinese uses the system font. Native controls become web equivalents with the same shapes: segmented controls, switches, a stepper, and date/time pills that open the system picker.

## Overview

PooPal is a sticker habit journal (手帐) for one person's gut. It is warm, soft and a little playful, and it stays tasteful.

- Every visit is a round die-cut sticker pressed onto the day.
- A small round marigold buddy, the "Pal", greets you, and its face follows how you're doing.
- It is a mobile-first web app (PWA) in Operate mode, shaped like a native mobile app: grouped forms, bottom sheets, a floating tab bar.
- Personality lives in color, stickers, the buddy, the wordmark, copy and motion.

It refuses two looks: the clinical health dashboard (teal, stat-card grids, a business tone) and the cartoon-poop kids' app. The buddy is abstract and never poop-shaped, and there is no emoji anywhere.

Light and dark are both first-class. Users pick 跟随系统 / 浅色 / 深色 in 设置 › 看起来 › 外观 (stored in localStorage under `poopal.appearance`), applied as `data-theme` on `<html>` before first paint by `public/theme-init.js`.

## Colors

- **Ground and surfaces.** `ground` is a warm milk in light mode and a plum-black in dark. `surface` holds grouped content; `surface-sunk` marks an empty past day; `line` is the hairline between rows.
- **Sunny marigold** is the brand field: the log sticker, the buddy and the icon. Text on marigold always uses `on-sunny` (deep plum), never white.
- **Plum** (`accent`) is the one interactive tint: controls, today and selected rings, the count numeral, the current chart bar, links in the toast.
- **Day stickers** (`day-1` to `day-3`) step from pale butter to marigold to tangerine as the count rises. They stay bright in dark mode, because real stickers do, and they are never darkened into brown. Numerals on them are always `day-ink`.
- **Bristol states:** tangerine `dry` (types 1–2), leaf `ideal` (types 3–5) and sky `loose` (types 6–7), each with a pale tint for its sticker. Pale tints stay light in dark mode (stickers are paper), and glyphs on them use the fixed deep `*-ink` shades. `alert` (rose) is only for undo, delete and warnings.

## Typography

SF Pro Rounded everywhere (`--font` on `body`), with these text-style sizes in px: large title 34, title 28, title3 20, body 17, subheadline 15, footnote 13, caption 12/11. Numbers use `font-variant-numeric: tabular-nums` (`.num`). The primary action ("记一下") is heavy, and section titles are bold. The `Logotype` wordmark is the only display voice.

## Layout

- **Margins and spacing:** 20pt screen edges and 30pt between home sections.
- **Home first viewport:**
  - The wordmark sits top-left with the settings gear top-right; there is no navigation bar.
  - Below them come the greeting with the date, "今天 N 次" in large title, and a plum "距上次 X" line followed by the mood sentence. The buddy (76pt) sits on the right of this block.
  - Next is the full-width marigold log sticker, then the capsule "忘了记？补一条" button, then this week's seven round stickers.
- **Statistics:** Home shows only a short "最近怎么样" panel (近 7 天来了, 大概多久一次, most common type). The full table lives in 趋势 under a collapsed "全部数字". Both are plain label/value rows, never a card grid.
- **贴纸本 (History)** has a large title "我的贴纸本" with the 日历 / 列表 / 趋势 segmented control in the navigation bar. 趋势 opens with a sentence ("这周 N 次，上周 M 次") instead of a dashboard header.

## Elevation & Depth

- **Stickers** carry a die-cut edge (2.5pt in `sticker-edge`) and a small lift shadow (black 12%, radius 2.5, y 1.5).
- **The log sticker** has a 4pt edge and a soft marigold shadow in light mode (`sunny-deep` 25%, radius 14, y 6); in dark mode it uses a plain black shadow (35%, radius 10) so it doesn't glow.
- **Panels** have no border. In light mode they float on a faint warm shadow (`#5A3A2A` at 7%, radius 14, y 6); in dark mode they are flat.

## Shapes

- **Round:** day stickers, entry badges, settings icons, the buddy, and the capsule buttons.
- **Soft rectangles:** picker stickers (18), panels (24) and the log sticker (32).
- **Tilt:** stickers tilt a few degrees, the way hand-placed stickers do. Day stickers tilt deterministically by count, and selected picker stickers tilt −3°.

## Components

- **Logotype:** rounded monoline letters with round caps and stroke 0.28 of x-height. `eyes: true` adds pupils to the two "o"s of "Poo", and the app icon uses it at about 85% of the icon width (870 of 1024), on one line.
  - **App icon:** deep plum letters on a marigold gradient.
  - **Dark icon:** marigold letters on plum-black.
- **PalBuddy:** a marigold ellipse with a white edge, two dot eyes, blush cheeks and a mouth.
  - **Faces:** hello, beaming, smile, calm and worried, mapped from `PoopMood`.
  - **Motion:** it blinks every few seconds and hops when you log. Both are off under Reduce Motion.
- **LogStickerButton:** squishes when pressed (scale 0.95, bouncy spring).
  - Today's visits show as overlapping tilted entry stickers (up to 5, then "+N") in the top corner. Logging adds one and bursts 12 confetti dots in the state colors.
  - The buddy hops and the phone vibrates briefly where the browser supports the Vibration API. Confetti is skipped under `prefers-reduced-motion`.
- **WeekStickers / MonthMosaic / DaySticker:** each day is a round sticker.
  - Future days are dashed slots, and empty past days are flat sunk circles.
  - Today and the selected day get a plum ring.
  - On the calendar, days with more than one visit get a plum count badge.
- **BristolPicker:** a 4×2 grid of the seven types plus 不确定. A selected sticker fills with its state tint, lifts, tilts and scales up with a spring.
- **Toast:** a material capsule reading "记好啦 · HH:mm", with 加点细节 and 撤销.
- **Tab bar:** a floating frosted capsule with 今天 and 贴纸本; the active tab sits on a soft pill in plum.

## Voice

Casual and warm, like a friend checking in, for example "记一下", "忘了记？补一条", "最近怎么样", "记好啦", "肠道小伙伴给你比个心". Health advice stays plain and kind, and the copy is never crude.

## Do's and Don'ts

- Do keep the native-app shapes: grouped rows in soft panels, switches, a stepper, segmented controls and date/time pills that open the system picker, tinted plum.
- Do keep touch targets at 44pt minimum.
- Do respect Reduce Motion: no blink, hop or confetti.
- Don't use emoji, poop shapes, or white text on marigold.
- Don't tint chrome with the state colors (tangerine, leaf, sky). Exception: the small settings icon circles.
- Don't use same-size stat card grids.
- Don't set the wordmark in a font.
