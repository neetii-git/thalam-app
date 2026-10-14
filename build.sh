#!/bin/bash
# Builds Thalam from the command line on a Mac:
#   1. installs XcodeGen with Homebrew if it's missing
#   2. generates Thalam.xcodeproj from project.yml
#   3. builds the iPhone app and the Watch app for the Simulator
#
# Usage:  ./build.sh          (build only)
#         ./build.sh --open   (build, then open the project in Xcode)
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "XcodeGen needs Homebrew. Install it from https://brew.sh and run this again."
    exit 1
  fi
  echo "==> Installing XcodeGen"
  brew install xcodegen
fi

echo "==> Generating Thalam.xcodeproj"
xcodegen generate

echo "==> Building iPhone app (with embedded Watch app) for iOS Simulator"
xcodebuild -project Thalam.xcodeproj -scheme Thalam \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO -quiet build

echo "==> Building Watch app for watchOS Simulator"
xcodebuild -project Thalam.xcodeproj -scheme "Thalam Watch App" \
  -destination 'generic/platform=watchOS Simulator' \
  CODE_SIGNING_ALLOWED=NO -quiet build

echo "==> Both targets build."

if [[ "${1:-}" == "--open" ]]; then
  open Thalam.xcodeproj
fi
