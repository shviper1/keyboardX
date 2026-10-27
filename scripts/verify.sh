#!/bin/zsh
# Local verification that works with only the Xcode Command Line Tools installed.
#   1. Syntax-parse every Swift file (UIKit files can't be type-checked without the iOS SDK).
#   2. Type-check + run the Foundation-only logic tests on macOS via a tiny XCTest shim.
#   3. Lint plists / entitlements.
set -euo pipefail
cd "${0:A:h}/.."

echo "==> 1/3 Parsing all Swift sources"
swift_files=("${(@f)$(find Shared KeyboardExtension KeyboardXApp KeyboardXTests scripts -name '*.swift')}")
for f in $swift_files; do
  swiftc -parse "$f"
done
echo "    parsed ${#swift_files} files"

echo "==> 2/3 Building and running logic tests"
out="${TMPDIR:-/tmp}/kbx_logic_tests"
modcache="${TMPDIR:-/tmp}/kbx_modcache"
swiftc -module-cache-path "$modcache" -O -o "$out" \
  Shared/AppGroup.swift \
  Shared/ClipboardStore.swift \
  KeyboardExtension/Layout/KeyboardLayout.swift \
  KeyboardExtension/Input/KeyboardState.swift \
  KeyboardExtension/Input/TextContext.swift \
  KeyboardXTests/*.swift \
  scripts/LogicTestHarness/XCTestShim.swift \
  scripts/LogicTestHarness/main.swift
"$out"

echo "==> 3/3 Linting plists"
plutil -lint KeyboardExtension/Info.plist KeyboardXApp/Info.plist \
  KeyboardExtension/KeyboardExtension.entitlements KeyboardXApp/KeyboardXApp.entitlements

echo "\nAll local checks passed ✅"
