# cineplay_pip

Optional native Picture-in-Picture (PiP) plugin for [`cineplay`](https://pub.dev/packages/cineplay).

Provides a backend-neutral Dart session API that carries source URI, playback position, speed, normalized volume, mute state, video dimensions, source rectangle, and localized play/pause labels across native PiP transitions.

---

## Platform Support

- **Android 8+**: Enters Android system PiP with the active Flutter activity/texture, auto-enter on Android 12+, and system play/pause action buttons.
- **iOS**: Uses `AVKit` PiP backed by the active FVP player when available, or a synchronized `AVPlayer` fallback for the same URI.
- **macOS**: Uses `AVKit` PiP with a synchronized `AVPlayer` session.
- **Web, Windows, Linux**: `isSupported()` returns `false` so hosts can fall back to browser PiP or `FVideoDesktopWindows.setCurrentWindowAlwaysOnTop(true)`.

---

## Installation

```yaml
dependencies:
  cineplay_pip: ^0.7.0
```

## Android Setup

Add `android:supportsPictureInPicture="true"` to your `MainActivity` in `AndroidManifest.xml`, and forward lifecycle callbacks to `com.iebb.cineplay_pip.FVideoPictureInPicturePlugin`:

- `onStart`, `onResume`, `onPause`, `onStop`, `onDestroy`
- `onUserLeaveHint`
- `onPictureInPictureRequested`
- `onPictureInPictureModeChanged`

See [`packages/cineplay/example`](../cineplay/example) for a complete Kotlin example.

## iOS Setup

Enable **Audio, AirPlay, and Picture in Picture** under Signing & Capabilities → Background Modes.

---

## Usage

```dart
import 'package:cineplay_pip/cineplay_pip.dart';

final started = await FVideoPictureInPicture.start(
  id: 'video-42',
  uri: Uri.parse('https://example.com/video.mp4'),
  position: controller.value.position,
  speed: controller.value.playbackSpeed,
  volume: controller.value.volume,
  muted: controller.value.volume == 0,
  playing: controller.value.isPlaying,
  videoSize: controller.value.size,
  onActionRequested: (action) async {
    switch (action) {
      case FVideoPictureInPictureAction.play:
        await controller.play();
      case FVideoPictureInPictureAction.pause:
        await controller.pause();
    }
  },
  onRestoreRequested: (snapshot) async {
    await controller.seekTo(snapshot.position);
    await controller.setPlaybackSpeed(snapshot.speed);
    await controller.setVolume(snapshot.muted ? 0 : snapshot.volume);
    return true;
  },
);
```

## License

BSD-3-Clause.
