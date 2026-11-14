#!/bin/zsh
# Runs PooPalTests against the pure statistics code on macOS using the Xcode
# toolchain directly. Useful when xcodebuild/simctl are unavailable; normally
# prefer `xcodebuild test` (see README).
set -euo pipefail

ROOT=${0:A:h:h}
DEV=$(xcode-select -p)
TC=$DEV/Toolchains/XcodeDefault.xctoolchain/usr/bin
SDK=$DEV/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
PLAT_FW=$DEV/Platforms/MacOSX.platform/Developer/Library/Frameworks
PLAT_LIB=$DEV/Platforms/MacOSX.platform/Developer/usr/lib
OUT=$ROOT/scripts/.out
mkdir -p "$OUT"

"$TC/swiftc" -sdk "$SDK" -module-name PooPal -enable-testing -parse-as-library \
  -emit-library -emit-module -static -o "$OUT/libPooPal.a" -emit-module-path "$OUT/PooPal.swiftmodule" \
  "$ROOT/Shared/PoopStats.swift" "$ROOT/Shared/BristolType.swift" "$ROOT/Shared/Theme.swift"

cat > "$OUT/main.swift" <<'EOF'
import XCTest
let suite = XCTestSuite(forTestCaseClass: PoopStatsTests.self)
suite.run()
let run = suite.testRun!
print("Executed \(run.executionCount) tests, \(run.totalFailureCount) failures")
exit(run.hasSucceeded ? 0 : 1)
EOF

"$TC/swiftc" -sdk "$SDK" -I "$OUT" -L "$OUT" -lPooPal \
  -F "$PLAT_FW" -I "$PLAT_LIB" -L "$PLAT_LIB" \
  -Xlinker -rpath -Xlinker "$PLAT_FW" -Xlinker -rpath -Xlinker "$PLAT_LIB" \
  -o "$OUT/PooPalLogicTests" "$ROOT/PooPalTests/PoopStatsTests.swift" "$OUT/main.swift"

"$OUT/PooPalLogicTests"
