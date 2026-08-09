#!/bin/zsh
set -euo pipefail
echo "XCUITest requires Accessibility automation permission for Xcode and its test runner."
echo "If this fails with 'Timed out while enabling automation mode', enable Xcode in System Settings > Privacy & Security > Accessibility, then rerun."
xcodebuild test -project Atmosphere.xcodeproj -scheme Atmosphere -destination 'platform=macOS' -only-testing:AtmosphereUITests
