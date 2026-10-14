#!/bin/bash
# Builds Thalam from the command line on a Mac:
#   1. gets XcodeGen if it's missing (downloaded into ./tools, no Homebrew or password needed)
#   2. generates Thalam.xcodeproj from project.yml
#   3. builds the iPhone app and the Watch app for the Simulator
#
# Usage:  ./build.sh --open   (generate the project and open it in Xcode; use this to install)
#         ./build.sh          (generate, then build both apps for the Simulator)
set -euo pipefail
cd "$(dirname "$0")"

XCODEGEN_VERSION=2.44.1
XCODEGEN=xcodegen
if ! command -v xcodegen >/dev/null 2>&1; then
  XCODEGEN=tools/xcodegen/bin/xcodegen
  if [[ ! -x "$XCODEGEN" ]]; then
    echo "==> Downloading XcodeGen $XCODEGEN_VERSION"
    curl -fsSL -o tools/xcodegen.zip \
      "https://github.com/yonaskolb/XcodeGen/releases/download/$XCODEGEN_VERSION/xcodegen.zip"
    (cd tools && rm -rf xcodegen && unzip -q xcodegen.zip && rm xcodegen.zip)
  fi
fi

echo "==> Generating Thalam.xcodeproj"
"$XCODEGEN" generate

if [[ "${1:-}" == "--open" ]]; then
  open Thalam.xcodeproj
  exit 0
fi

echo "==> Building iPhone app (with embedded Watch app) for iOS Simulator"
xcodebuild -project Thalam.xcodeproj -scheme Thalam \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO -quiet build

echo "==> Building Watch app for watchOS Simulator"
xcodebuild -project Thalam.xcodeproj -scheme "Thalam Watch App" \
  -destination 'generic/platform=watchOS Simulator' \
  CODE_SIGNING_ALLOWED=NO -quiet build

echo "==> Both targets build."
