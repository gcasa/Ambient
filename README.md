# Atmosphere

A native Objective-C ambient-sound mixer for macOS 13 and later.

## Run

Open `Atmosphere.xcodeproj` in Xcode and press **Run**, or build from Terminal:

```sh
xcodebuild -project Atmosphere.xcodeproj -scheme Atmosphere -configuration Debug build
```

Atmosphere uses `AVAudioEngine` with bundled CC0 recordings scheduled through `AVAudioPlayerNodeBufferLoops`. If a recording is missing or unreadable, the engine automatically falls back to its procedural generator. Audio sources and license records are listed in `Atmosphere/Resources/Audio/LICENSES.md`.

Presets and preferences are stored in `NSUserDefaults`. The model uses stable sound identifiers and serializable dictionaries to leave room for uploaded files, cloud sync, sharing, offline packs, spatial positions, and a mobile UI.
