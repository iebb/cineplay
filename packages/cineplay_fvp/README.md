# cineplay_fvp

Optional [FVP / libmdk](https://github.com/wang-bin/fvp) playback backend adapter for [`cineplay`](https://pub.dev/packages/cineplay).

Provides hardware-accelerated multi-codec playback (HEVC, AV1, MKV, WebM, FLV, HLS, etc.), embedded audio & subtitle track selection, external subtitle loading, container chapters, exact native frame stepping, PNG frame snapshots, Linux bundled-FFmpeg scrub thumbnails, and optional Android alpha-WebM routing.

---

## Installation

```yaml
dependencies:
  cineplay: ^0.7.0
  cineplay_fvp: ^0.7.0
```

## Registration

Call `FVideoFvp.registerWith()` before creating any `VideoPlayerController` or `FVideoPlayer`:

```dart
import 'package:cineplay_fvp/cineplay_fvp.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FVideoFvp.registerWith();
  runApp(const MyApp());
}
```

By default, `FVideoFvp.registerWith()` registers FVP on desktop platforms without an official `video_player` backend (macOS, Windows, Linux) and installs the bundled-FFmpeg thumbnailer on Linux. You can explicitly select platforms via `FVideoFvpOptions(platforms: {...})`.

---

## Track Selection, Chapters, Frame Stepping & Snapshots

Use `FvpControllerBridge` with any initialized `VideoPlayerController`. Every method degrades safely (returning empty/null/false) on Web or non-FVP backends:

```dart
import 'package:cineplay_fvp/cineplay_fvp.dart';

// Audio & subtitle tracks
final audioTracks = FvpControllerBridge.audioTracks(controller);
FvpControllerBridge.selectAudioTrack(controller, audioTracks.first.id);

final subtitleTracks = FvpControllerBridge.subtitleTracks(controller);
FvpControllerBridge.selectSubtitleTrack(controller, subtitleTracks.first.id);
// Pass null to disable subtitles:
FvpControllerBridge.selectSubtitleTrack(controller, null);
// Or attach an external .srt / .vtt file:
FvpControllerBridge.setExternalSubtitle(controller, '/path/to/subs.srt');

// Container chapters (MKV/MP4)
final chapters = FvpControllerBridge.chapters(controller);

// Exact frame stepping & PNG frame capture
await FvpControllerBridge.stepFrames(controller, 1);
final pngBytes = await FvpControllerBridge.captureFramePng(controller);
```

Wire directly into `FVideoPlayer`:

```dart
FVideoPlayer(
  source: source,
  chapters: FvpControllerBridge.chapters(controller),
  frameStepDelegate: (frames) => FvpControllerBridge.stepFrames(controller, frames),
  snapshotDelegate: ({width, height}) =>
      FvpControllerBridge.captureFramePng(controller, width: width, height: height),
);
```

## License

BSD-3-Clause. See the repository's `THIRD_PARTY_NOTICES.md` for FVP/libmdk licensing terms.
