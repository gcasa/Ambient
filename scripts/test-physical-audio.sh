#!/bin/zsh
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <output-device-name> [timeout-seconds]"
  echo "Find names with: system_profiler SPAudioDataType"
  exit 64
fi
device_name=$1
timeout_seconds=${2:-60}
config=/tmp/AtmosphereHardwareInteraction.plist
trap 'rm -f "$config"' EXIT
plutil -create xml1 "$config"
plutil -insert Mode -string unplug "$config"
plutil -insert DeviceName -string "$device_name" "$config"
plutil -insert Timeout -integer "$timeout_seconds" "$config"
xcodebuild test -project Atmosphere.xcodeproj -scheme AtmosphereHardwareTests -destination 'platform=macOS' -only-testing:AtmosphereTests/AtmosphereTests/testPhysicalOutputUnplugAndReconnect
