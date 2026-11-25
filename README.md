# Cineplay

**A cross-platform Flutter video player built for desktop, mobile, and web.**

[![CI](https://github.com/iebb/cineplay/actions/workflows/ci.yml/badge.svg)](https://github.com/iebb/cineplay/actions/workflows/ci.yml)

Cineplay gives Flutter apps a fast, accessible, zero-Material/Cupertino video player core with replaceable chrome, chapter markers, scrub preview caching, keyboard-first desktop ergonomics, independent multi-window playback, optional hardware-accelerated FVP/MDK decoding, and native Picture-in-Picture.

---

## Packages

| Package | Purpose | Path |
| --- | --- | --- |
| **`cineplay`** | Core video player widget, timeline slider with chapter markers, LRU scrub thumbnail cache, keyboard shortcuts, and independent desktop windows. Pure Flutter (`flutter/widgets.dart` only). | [`packages/cineplay`](packages/cineplay) |
| **`cineplay_fvp`** | Optional [FVP / libmdk](https://github.com/wang-bin/fvp) backend adapter for hardware-accelerated multi-codec playback, embedded audio & subtitle tracks, container chapters, exact frame stepping, PNG snapshots, and Linux FFmpeg thumbnails. | [`packages/cineplay_fvp`](packages/cineplay_fvp) |
| **`cineplay_pip`** | Optional native Picture-in-Picture plugin for Android 8+, iOS (`AVKit`), and macOS (`AVKit`) with play/pause actions and restore-to-app snapshots. | [`packages/cineplay_pip`](packages/cineplay_pip) |

---

## Platform Support

| Platform | Core Player (`cineplay`) | FVP/MDK Backend (`cineplay_fvp`) | Native PiP (`cineplay_pip`) | Detached Windows |
| --- | :---: | :---: | :---: | :---: |
| **macOS** | Yes | Yes | Yes (`AVKit`) | Yes (+ Always-on-Top) |
| **Windows** | Yes | Yes | Host fallback | Yes (+ Always-on-Top) |
| **Linux** | Yes | Yes (+ bundled FFmpeg thumbnails) | Host fallback | Yes (+ Always-on-Top) |
| **iOS** | Yes | Yes | Yes (`AVKit`) | — |
| **Android** | Yes | Yes (+ alpha WebM routing) | Yes (Android 8+) | — |
| **Web** | Yes | No-op stub (uses HTML5 video) | Host fallback | — |
| **HarmonyOS** | Yes | Yes | — | — |

---

## Key Capabilities

- **Zero UI-kit lock-in**: Core `cineplay` depends only on `flutter/widgets.dart` (enforced by automated design-policy tests)—no Material, Cupertino, or icon-font dependencies.
- **Replaceable chrome**: Use the built-in high-contrast accessible chrome or pass `chromeBuilder` to render your own UI against an immutable `FVideoChromeSnapshot` and safe `FVideoActions` facade.
- **Desktop-grade controls & shortcuts**:
  - `Space` / `K` play/pause · `J` / `L` / `←` / `→` seek · `↑` / `↓` volume · `M` mute
  - `0`–`9` jump to 0%–90% · `[` / `]` playback speed · `Backspace` reset to 1×
  - `,` / `.` frame-by-frame step · `R` rotate 90° · `Z` toggle Fit/Fill
  - `F` fullscreen · `P` Picture-in-Picture · `Esc` exit fullscreen/PiP/close
- **Chapters & timestamp parsing**: `FVideoChapter.parseFromText` turns `mm:ss` / `h:mm:ss` descriptions into timeline tick markers and active chapter state.
- **Smooth scrubbing**: `FVideoThumbnailCache` quantizes scrub positions into LRU buckets and deduplicates in-flight decodes.
- **Reliable auto-hide**: Ignores stationary/sub-pixel pointer jitter on desktop, hides promptly on pointer exit, and always honors explicit tap/click hiding even when system accessibility services are active.
- **Independent desktop windows**: Open multiple native player windows on macOS, Windows, and Linux with fullscreen and always-on-top pinning via `FVideoDesktopWindows`.

---

## Quick Start

```yaml
dependencies:
  cineplay: ^0.7.0
  # Optional: hardware-accelerated desktop/cross-platform decoding & tracks
  cineplay_fvp: ^0.7.0
  # Optional: native Android/iOS/macOS Picture-in-Picture
  cineplay_pip: ^0.7.0
```

```dart
import 'package:cineplay/cineplay.dart';
import 'package:flutter/widgets.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FVideoPlayer(
      source: const FVideoSource.network('https://example.com/movie.mp4'),
      autofocus: true,
      enableScrollVolume: true,
      chapters: FVideoChapter.parseFromText('''
        0:00 Opening
        01:30 Main Story
        05:00 Credits
      '''),
    );
  }
}
```

---

## Repository Structure

```text
packages/
  cineplay/           # Core player package + multi-platform example app
  cineplay_fvp/       # Optional FVP/MDK backend & FvpControllerBridge
  cineplay_pip/       # Optional native PiP plugin (Android, iOS, macOS)
third_party/
  fvp/                # Vendored FVP bridge with verified Apple MDK tooling
  fc_native_video_thumbnail/
```

---

## Development & Testing

```bash
# Core package
cd packages/cineplay && flutter analyze --fatal-infos && flutter test

# FVP adapter
cd packages/cineplay_fvp && flutter analyze --fatal-infos && flutter test

# PiP plugin
cd packages/cineplay_pip && flutter analyze --fatal-infos && flutter test

# Example app
cd packages/cineplay/example && flutter analyze --fatal-infos && flutter test
```

---

## Automated Publishing (GitHub Actions + pub.dev OIDC)

[`.github/workflows/publish.yml`](.github/workflows/publish.yml) publishes `cineplay`, `cineplay_pip`, and `cineplay_fvp` in dependency order and creates a GitHub Release whenever a `v*` tag is pushed (or runs a safe dry-run via manual `workflow_dispatch`).

1. Upload the initial version of each package once manually (`flutter pub publish`) so you own the package on pub.dev.
2. In pub.dev **Admin → Automated publishing**, enable GitHub Actions for `iebb/cineplay` with tag pattern `v{{version}}`.
3. From then on, bump versions in the three `pubspec.yaml` + `CHANGELOG.md` files and push a matching `vX.Y.Z` tag.

## License

BSD-3-Clause. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
