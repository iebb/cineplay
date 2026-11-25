# cineplay

A responsive, accessible, cross-platform Flutter video player with zero Material or Cupertino dependencies, replaceable chrome, chapter markers, scrub preview caching, keyboard shortcuts, and independent desktop windows.

---

## Features

- **Pure `flutter/widgets.dart` core**: No Material, Cupertino, or built-in icon font dependencies.
- **Works everywhere**: macOS, Windows, Linux, iOS, Android, Web, and HarmonyOS.
- **Replaceable chrome**: Built-in high-contrast default controls, or supply your own `chromeBuilder` powered by immutable `FVideoChromeSnapshot` and `FVideoActions`.
- **Chapters & timeline ticks**: `FVideoChapter` + `FVideoChapter.parseFromText` + `FVideoSlider` chapter tick markers.
- **Viewer transforms & precision controls**: Live loop toggle, 90° clockwise rotation, Fit/Fill toggle, frame-by-frame stepping, and frame snapshot capture.
- **LRU scrub thumbnail cache**: `FVideoThumbnailCache` with bucket quantization and in-flight deduplication.
- **Reliable control auto-hide**: Filters sub-pixel mouse jitter, hides promptly on pointer exit, and always lets explicit taps hide controls even when system accessibility services are enabled.
- **Independent desktop windows**: Native multi-window playback on macOS, Windows, and Linux with fullscreen and always-on-top pinning (`FVideoDesktopWindows`).

---

## Quick Start

```yaml
dependencies:
  cineplay: ^0.7.0
```

```dart
import 'package:cineplay/cineplay.dart';
import 'package:flutter/widgets.dart';

class MovieView extends StatelessWidget {
  const MovieView({super.key});

  @override
  Widget build(BuildContext context) {
    return FVideoPlayer(
      source: const FVideoSource.network('https://example.com/sample.mp4'),
      autofocus: true,
      enableScrollVolume: true,
      chapters: const [
        FVideoChapter(position: Duration.zero, title: 'Intro'),
        FVideoChapter(position: Duration(minutes: 1, seconds: 20), title: 'Scene 1'),
      ],
    );
  }
}
```

### Media Sources

```dart
const FVideoSource.network('https://example.com/video.mp4', httpHeaders: {'Authorization': 'Bearer ...'});
const FVideoSource.file('/path/to/video.mp4');
const FVideoSource.asset('assets/intro.mp4');
FVideoSource.uri(Uri.parse('https://example.com/video.mp4'));
```

---

## Keyboard Shortcuts

Enabled by default (`enableKeyboardShortcuts: true`) when the player has focus:

| Key | Action |
| --- | --- |
| `Space` / `K` | Play / Pause |
| `←` / `J` | Seek backward (`seekInterval`, default 10s) |
| `→` / `L` | Seek forward (`seekInterval`, default 10s) |
| `0`–`9` | Jump to 0%–90% of duration |
| `↑` / `↓` | Volume up / down (`volumeStep`, default 5%) |
| `M` | Toggle mute |
| `[` / `]` | Decrease / increase playback speed |
| `Backspace` | Reset playback speed to `1.0×` |
| `,` / `.` | Pause and step 1 frame backward / forward |
| `R` | Rotate video 90° clockwise |
| `Z` | Toggle Fit (`BoxFit.contain`) / Fill (`BoxFit.cover`) |
| `F` | Toggle fullscreen |
| `P` | Toggle Picture-in-Picture (when `onPictureInPictureChanged` is set) |
| `Esc` | Exit fullscreen → exit PiP → invoke `onClose` |

---

## Chapters & Timestamp Parsing

Parse YouTube/Telegram-style descriptions directly into sorted chapter markers:

```dart
final chapters = FVideoChapter.parseFromText(
  '''
  0:00 Opening
  02:15 - Architecture
  1:04:10 Wrap-up
  ''',
  maxDuration: controller.value.duration,
);
```

Pass `chapters` to `FVideoPlayer` to render tick markers on the timeline and expose `scope.snapshot.currentChapter` plus `scope.actions.seekToChapter(...)`, `nextChapter()`, and `previousChapter()`.

---

## Scrub Preview Caching

Use `FVideoThumbnailCache` to quantize scrub positions and avoid redundant decodes or range fetches:

```dart
final cache = FVideoThumbnailCache(
  maxEntries: 48,
  bucketDuration: const Duration(seconds: 1),
);

FVideoPlayer(
  source: source,
  thumbnailProvider: (request) => cache.resolve(request),
);
```

---

## Custom Chrome

Provide `chromeBuilder` to build a bespoke UI while keeping focus, keyboard shortcuts, lifecycle handling, buffering, rotation, fit, and captions player-owned:

```dart
FVideoPlayer(
  source: source,
  chromeBuilder: (context, scope) {
    final snap = scope.snapshot;
    final actions = scope.actions;
    return AnimatedOpacity(
      opacity: snap.controlsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 170),
      child: Row(
        children: [
          GestureDetector(
            onTap: actions.togglePlayback,
            child: Text(snap.value.isPlaying ? 'Pause' : 'Play'),
          ),
          GestureDetector(
            onTap: actions.rotateClockwise,
            child: const Text('Rotate'),
          ),
          GestureDetector(
            onTap: actions.toggleFit,
            child: Text(snap.fit == BoxFit.cover ? 'Fit' : 'Fill'),
          ),
        ],
      ),
    );
  },
);
```

---

## Independent Desktop Windows

Open detached native player windows on macOS, Windows, and Linux:

```dart
if (fVideoSupportsDesktopVideoWindows) {
  await FVideoDesktopWindows.instance.open(
    FVideoDesktopWindowArguments(
      uri: Uri.parse('https://example.com/movie.mp4'),
      title: 'Movie',
      width: 1280,
      height: 720,
      muted: false,
    ),
  );
}
```

Inside a detached child window, control fullscreen and always-on-top pinning:

```dart
await FVideoDesktopWindows.setCurrentWindowFullscreen(true);
await FVideoDesktopWindows.toggleCurrentWindowAlwaysOnTop();
```

---

## Companion Packages

- **[`cineplay_fvp`](https://github.com/iebb/cineplay/tree/master/packages/cineplay_fvp)**: Optional FVP/MDK hardware-accelerated backend, audio/subtitle track selection, container chapters, exact frame stepping, and PNG snapshots.
- **[`cineplay_pip`](https://github.com/iebb/cineplay/tree/master/packages/cineplay_pip)**: Optional native Picture-in-Picture plugin for Android 8+, iOS, and macOS.

## License

BSD-3-Clause.
