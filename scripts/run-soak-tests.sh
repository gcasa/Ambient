#!/bin/zsh
set -euo pipefail
duration_seconds=${1:-14400}
config=/tmp/AtmosphereSoakTest.plist
trap 'rm -f "$config"' EXIT
plutil -create xml1 "$config"
plutil -insert DurationSeconds -integer "$duration_seconds" "$config"
xcodebuild test -project Atmosphere.xcodeproj -scheme AtmosphereHardwareTests -destination 'platform=macOS' -only-testing:AtmosphereTests/AtmosphereTests/testFourHourAudioSoak
