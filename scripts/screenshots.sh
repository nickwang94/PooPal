#!/bin/zsh
# Builds PooPal, runs it in an iPhone simulator with demo data and saves screenshots.
# Usage: scripts/screenshots.sh ["iPhone 17 Pro"]
set -euo pipefail

ROOT=${0:A:h:h}
DEVICE=${1:-}
OUT=$ROOT/screenshots
DERIVED=$ROOT/build/DerivedData
BUNDLE_ID=com.nickwang.PooPal
mkdir -p "$OUT"

if [[ -z "$DEVICE" ]]; then
  DEVICE=$(xcrun simctl list devices available | grep -E '^\s+iPhone' | head -1 | sed -E 's/^ +(.*) \([0-9A-F-]+\).*/\1/')
fi
UDID=$(xcrun simctl list devices available | grep -F "    $DEVICE (" | head -1 | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
echo "Simulator: $DEVICE ($UDID)"

xcodebuild -project "$ROOT/PooPal.xcodeproj" -scheme PooPal -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DERIVED" build -quiet

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>/dev/null || true
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true

APP=$DERIVED/Build/Products/Debug-iphonesimulator/PooPal.app
xcrun simctl install "$UDID" "$APP"

shot() {
  local name=$1; shift
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@" >/dev/null
  sleep 6
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null
  echo "saved $OUT/$name.png"
}

for mode in light dark; do
  shot v4-$mode-home -demoData -appearance $mode
  shot v4-$mode-home-stats -demoData -homeScroll stats -appearance $mode
  shot v4-$mode-history-calendar -demoData -startTab history -appearance $mode
  shot v4-$mode-history-list -demoData -startTab history -historyMode list -appearance $mode
  shot v4-$mode-trends -demoData -startTab history -historyMode trends -appearance $mode
  shot v4-$mode-add-entry -demoData -showAddEntry YES -appearance $mode
  shot v4-$mode-settings -demoData -showSettings YES -appearance $mode
  shot v4-$mode-empty -emptyStore -appearance $mode
done
