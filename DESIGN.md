---
name: PooPal
description: A private gut log set in a bathroom-tile world; every day is a glazed tile.
colors:
  ground: "#F2F5F4"
  ground-dark: "#0A1413"
  surface: "#FFFFFF"
  surface-dark: "#13201E"
  surface-sunk: "#E6EDEB"
  surface-sunk-dark: "#1B2B29"
  grout: "#D6E0DE"
  grout-dark: "#263A37"
  ink: "#0E1E1C"
  ink-dark: "#E4EFED"
  ink-soft: "#4A5E5B"
  ink-soft-dark: "#9BB2AE"
  glaze: "#0F5F59"
  glaze-dark: "#2F9A8F"
  glaze-deep: "#0A4642"
  glaze-deep-dark: "#1E6E66"
  glaze-light: "#6DB3AA"
  glaze-light-dark: "#2A7A72"
  glaze-pale: "#C4E2DD"
  glaze-pale-dark: "#1D4743"
  on-glaze: "#F3FBF9"
  action-top: "#0F5F59"
  action-top-dark: "#1C6B63"
  action-bottom: "#0A4642"
  action-bottom-dark: "#0F4541"
  mosaic-1: "#A8D5CE"
  mosaic-1-dark: "#1B4A45"
  mosaic-2: "#3E8C83"
  mosaic-2-dark: "#2A7F76"
  mosaic-3: "#0A4642"
  mosaic-3-dark: "#52C4B6"
  amber: "#C27A1E"
  amber-dark: "#E9A956"
  amber-pale: "#F6E2C4"
  amber-pale-dark: "#3F2E16"
  coral: "#C2513D"
  coral-dark: "#EE8A75"
  coral-pale: "#F6D6CF"
  coral-pale-dark: "#45231D"
typography:
  count:
    fontFamily: "SF Pro (system), monospaced digits"
    fontSize: "largeTitle"
    fontWeight: 700
  section-title:
    fontFamily: "SF Pro (system)"
    fontSize: "title3"
    fontWeight: 600
  body:
    fontFamily: "SF Pro (system)"
    fontSize: "body"
    fontWeight: 400
  data:
    fontFamily: "SF Pro (system), monospaced digits"
    fontSize: "body"
    fontWeight: 600
  caption:
    fontFamily: "SF Pro (system)"
    fontSize: "caption / caption2"
    fontWeight: 500
rounded:
  tile-sm: "3px"
  tile: "8px"
  tile-week: "10px"
  tile-picker: "12px"
  panel: "20px"
  action: "28px"
spacing:
  screen-edge: "20px"
  section-gap: "28px"
  tile-gap: "6px"
  panel-row: "16px"
components:
  log-tile-button:
    backgroundColor: "{colors.action-top}"
    textColor: "{colors.on-glaze}"
    rounded: "{rounded.action}"
    padding: "22px"
    height: "176px"
  panel:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.panel}"
  day-tile-0:
    backgroundColor: "{colors.surface-sunk}"
    textColor: "{colors.ink-soft}"
    rounded: "{rounded.tile}"
  day-tile-1:
    backgroundColor: "{colors.mosaic-1}"
    textColor: "{colors.glaze-deep}"
    rounded: "{rounded.tile}"
  day-tile-2:
    backgroundColor: "{colors.mosaic-2}"
    textColor: "{colors.on-glaze}"
    rounded: "{rounded.tile}"
  day-tile-3:
    backgroundColor: "{colors.mosaic-3}"
    textColor: "{colors.on-glaze}"
    rounded: "{rounded.tile}"
  bristol-tile:
    backgroundColor: "{colors.glaze-pale}"
    textColor: "{colors.ink}"
    rounded: "{rounded.tile-picker}"
    height: "84px"
  settings-icon:
    backgroundColor: "{colors.glaze}"
    textColor: "{colors.on-glaze}"
    rounded: "7px"
    size: "29px"
---

# PooPal design system

Source of truth: `Shared/Theme.swift` (tokens, `GlazeTile`, `.panel()`), `Shared/Logotype.swift` (the wordmark), `Shared/BristolType.swift` (state colors). Every color is a light/dark pair built with `Theme.dynamic(light:dark:)`; the `-dark` keys above are the dark halves of the same token, not separate tokens.

## Overview

A bathroom-tile world for a private gut log. Porcelain ground, one committed glaze teal, and rounded-square tiles with a soft glaze highlight. Every day is a tile; logging fills tiles. Operate mode on iOS: native navigation, forms, pickers and Dynamic Type everywhere; the identity lives in color, tiles and the wordmark, not in custom chrome.

It refuses the category default: pastel cards, a cartoon mascot, emoji, and a grid of same-size stat cards.

Light and dark are both first-class. Users pick 跟随系统 / 浅色 / 深色 in 设置 › 显示 › 外观 (`Appearance`, stored under `appearance`), applied with `preferredColorScheme` at the root.

## Colors

- **Ground and surfaces.** `ground` is the screen; `surface` holds grouped content; `surface-sunk` is an empty tile; `grout` is the hairline between rows and the panel border.
- **Glaze** is the only brand and action color: primary button, selection, today/selected rings, chart current bucket, settings icons, tint.
- **Action** (`action-top` → `action-bottom`) is the big log tile's gradient. It is dimmer in dark so the brightest object on screen does not glare at night.
- **Mosaic** levels 1–3 encode a day's count. Lightness moves monotonically toward "more" in each appearance: darker in light mode, brighter in dark mode. Always pair a tile color with `Theme.tileInk(for:)` for numerals.
- **Amber and coral are reserved** for Bristol dry (types 1–2) and loose (types 6–7). Types 3–5 use glaze. Never use amber or coral for chrome, icons or emphasis.

## Typography

SF Pro only, via Dynamic Type text styles (`largeTitle`, `title3`, `headline`, `body`, `subheadline`, `footnote`, `caption`, `caption2`). Every number uses `.monospacedDigit()`. The only display voice is the `Logotype` wordmark; never set "PooPal" in a font.

## Layout

20pt screen edges, 28pt between home sections, 6–8pt between tiles. The home first viewport: wordmark left and settings gear right (no navigation bar), date, the "今天 N 次" count line, status sentence, the full-width log tile (about a quarter of the screen), then 补记一次, then this week's seven tiles. Stats are plain label/value rows in one panel, never a card grid. 记录 puts its 日历 / 列表 / 趋势 segmented control in the navigation bar.

## Elevation & Depth

Flat by default. `GlazeTile` carries a 1pt offset shadow (black 10%, radius 1.5) and a top-half white highlight (22% → clear); that is the whole tile vocabulary. The log tile adds a teal drop shadow (glaze-deep 35%, radius 14, y 8) and a radial highlight (16% light, 8% dark). Panels have no shadow, only a 0.5pt grout border.

## Shapes

Continuous rounded rectangles throughout. Radius scales with size: 3 (legend swatch), 7 (settings icon), 8 (calendar day), 10 (week day), 12 (Bristol picker), 20 (panels), 28 (log tile).

## Components

- **Logotype** (`.line` / `.stacked`): monoline geometric wordmark drawn in a Canvas, butt caps, stroke 0.25 of x-height. In-app at 22pt high; the app icon is the `.line` layout at about 78% of the icon width on flat glaze.
- **LogTileButton**: the primary action. Today's entries appear inside it as six small tiles; tapping logs now with success haptics and an undo toast.
- **WeekMosaic / MonthMosaic / DayTile**: count tiles with `tile(for:)` / `tileInk(for:)`. Today gets a glaze ring; the selected day gets a 2pt glaze ring.
- **BristolPicker**: a 4×2 grid of the seven types plus 不确定. Unselected tiles use the type's pale tint; selected tiles fill with the type's tint. The group and hint footnote appears only once a type is chosen.
- **EntryBadge / BristolGlyph**: monochrome drawings of each type, with no faces.
- **Panel** (`.panel()`): surface fill, 20pt radius, grout hairline, rows separated by inset dividers.
- **Widget**: a glaze-gradient container, an on-glaze wordmark and counts, and a porcelain 记一次 button that runs `LogPoopIntent`.

## Do's and Don'ts

- Do use native `Form`, `List`, `Picker`, `Stepper`, `DatePicker` and segmented controls; tint them glaze.
- Do keep touch targets at 44pt minimum.
- Don't add emoji, mascots or faces.
- Don't add eyebrow or kicker labels.
- Don't put a second accent color in chrome.
- Don't use same-size stat card grids.
- Don't use colored text on colored tiles without checking contrast in both appearances.
