# Atmosphere

A native Objective-C ambient-sound mixer for macOS 13 and later.

## Run

Open `Atmosphere.xcodeproj` in Xcode and press **Run**, or build from Terminal:

```sh
xcodebuild -project Atmosphere.xcodeproj -scheme Atmosphere -configuration Debug build
```

Atmosphere uses AVAudioEngine and procedural demo audio, so it works without downloads. For production, add licensed seamless audio to `Atmosphere/Resources/Audio`, set each catalog item's `resourceName`, and replace the procedural source in `ATAudioEngine.m` with an `AVAudioPlayerNode` scheduled with `AVAudioPlayerNodeBufferLoops`.

Presets and preferences are stored in `NSUserDefaults`. The model uses stable sound identifiers and serializable dictionaries to leave room for uploaded files, cloud sync, sharing, offline packs, spatial positions, and a mobile UI.
