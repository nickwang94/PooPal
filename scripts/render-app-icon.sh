#!/bin/zsh
set -euo pipefail

ROOT=${0:A:h:h}
DEV=$(xcode-select -p)
TC=$DEV/Toolchains/XcodeDefault.xctoolchain/usr/bin
SDK=$DEV/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
OUT=$ROOT/scripts/.out
mkdir -p "$OUT"

"$TC/swiftc" -sdk "$SDK" -parse-as-library -o "$OUT/render-app-icon" \
  "$ROOT/scripts/render-app-icon.swift" \
  "$ROOT/PooPal/Theme/Theme.swift" \
  "$ROOT/PooPal/Views/PoopMascot.swift"

"$OUT/render-app-icon" "$ROOT/PooPal/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
