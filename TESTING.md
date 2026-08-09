# Testing Atmosphere

The regular XCTest target covers functional, performance, stress, sleep/wake, and real default-output switching. Tests that require an operator or several hours skip unless launched by their scripts.

## UI automation

Run `scripts/run-ui-tests.sh`. The Mac must grant Accessibility automation permission to Xcode and its test runner. macOS intentionally requires a user or managed-device policy to grant this; the app cannot grant it to itself. The self-hosted `accessibility-enabled` CI job runs all three UI workflows on a pre-authorized Mac.

## Physical output removal

Find the output name with `system_profiler SPAudioDataType`, then run `scripts/test-physical-audio.sh "<device name>"`. Follow the test log prompts to unplug and reconnect the device. The test fails if either transition does not occur before the timeout.

For Bluetooth, run `scripts/test-bluetooth-audio.sh "<device name>"`. Power off or disconnect the device when prompted, then reconnect it. The test verifies Bluetooth transport, delayed disappearance/reappearance, and AVAudioEngine recovery. Changing between headset and high-quality profiles during the reconnect exercises profile renegotiation.

## Soak test

`scripts/run-soak-tests.sh` runs for four hours by default. Pass a duration in seconds for a shorter diagnostic run. It cycles eight voices, pause/resume, and volume state while enforcing a 200 MB resident-memory-growth ceiling.

## Compatibility

GitHub Actions tests macOS 14, 15, and 26 on Intel and Apple Silicon, and builds a universal binary with a macOS 13 deployment target. Runtime testing on macOS 13 requires the manually dispatched self-hosted `macos-13` Intel runner because GitHub no longer provides a hosted macOS 13 image.
