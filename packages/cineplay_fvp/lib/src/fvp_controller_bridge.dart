import 'dart:async';
import 'dart:ui' as ui;

import 'package:cineplay/cineplay.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart';
import 'package:video_player/video_player.dart';

/// Safe adapter exposing FVP/MDK track selection, container chapters, exact
/// frame stepping, and frame snapshot capture for a [VideoPlayerController].
///
/// Every method degrades gracefully (returning empty/null or no-op) when the
/// active [VideoPlayerController] is not backed by FVP/MDK (for example on web
/// or when an Android compatibility fallback uses ExoPlayer).
abstract final class FvpControllerBridge {
  static List<FVideoAudioTrack> audioTracks(VideoPlayerController controller) {
    try {
      final info = controller.getMediaInfo();
      final streams = info?.audio;
      if (streams == null || streams.isEmpty) return const [];
      return [
        for (var i = 0; i < streams.length; i++)
          FVideoAudioTrack(
            id: i,
            label: _trackLabel(
              metadata: streams[i].metadata,
              fallbackPrefix: 'Audio',
              displayIndex: i + 1,
            ),
            language: _trackLanguage(streams[i].metadata),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static int? activeAudioTrackId(VideoPlayerController controller) {
    try {
      final active = controller.getActiveAudioTracks();
      if (active == null || active.isEmpty) return null;
      return active.first;
    } catch (_) {
      return null;
    }
  }

  static bool selectAudioTrack(VideoPlayerController controller, int? trackId) {
    try {
      controller.setAudioTracks(trackId == null ? const [-1] : [trackId]);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<FVideoSubtitleTrack> subtitleTracks(
    VideoPlayerController controller,
  ) {
    try {
      final info = controller.getMediaInfo();
      final streams = info?.subtitle;
      if (streams == null || streams.isEmpty) return const [];
      return [
        for (var i = 0; i < streams.length; i++)
          FVideoSubtitleTrack(
            id: i,
            label: _trackLabel(
              metadata: streams[i].metadata,
              fallbackPrefix: 'Subtitle',
              displayIndex: i + 1,
            ),
            language: _trackLanguage(streams[i].metadata),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static int? activeSubtitleTrackId(VideoPlayerController controller) {
    try {
      final active = controller.getActiveSubtitleTracks();
      if (active == null || active.isEmpty) return null;
      final id = active.first;
      return id < 0 ? null : id;
    } catch (_) {
      return null;
    }
  }

  static bool selectSubtitleTrack(
    VideoPlayerController controller,
    int? trackId,
  ) {
    try {
      controller.setSubtitleTracks(trackId == null ? const [-1] : [trackId]);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool setExternalSubtitle(
    VideoPlayerController controller,
    String uri,
  ) {
    if (uri.trim().isEmpty) return false;
    try {
      controller.setExternalSubtitle(uri);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<FVideoChapter> chapters(VideoPlayerController controller) {
    try {
      final info = controller.getMediaInfo();
      final rawChapters = info?.chapters;
      if (rawChapters == null || rawChapters.isEmpty) return const [];
      final result = <FVideoChapter>[
        for (var i = 0; i < rawChapters.length; i++)
          FVideoChapter(
            position: Duration(
              milliseconds: rawChapters[i].startTime < 0
                  ? 0
                  : rawChapters[i].startTime,
            ),
            title: (rawChapters[i].title ?? '').trim().isNotEmpty
                ? rawChapters[i].title!.trim()
                : 'Chapter ${i + 1}',
          ),
      ]..sort((a, b) => a.position.compareTo(b.position));
      return List<FVideoChapter>.unmodifiable(result);
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> stepFrames(
    VideoPlayerController controller,
    int frames,
  ) async {
    if (frames == 0) return true;
    try {
      await controller.step(frames: frames);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Captures the currently displayed frame from MDK and encodes it as PNG.
  static Future<Uint8List?> captureFramePng(
    VideoPlayerController controller, {
    int? width,
    int? height,
  }) async {
    try {
      final videoSize = controller.value.size;
      final targetWidth =
          width ?? (videoSize.width > 0 ? videoSize.width.round() : null);
      final targetHeight =
          height ?? (videoSize.height > 0 ? videoSize.height.round() : null);
      if (targetWidth == null ||
          targetHeight == null ||
          targetWidth <= 0 ||
          targetHeight <= 0) {
        return null;
      }
      final rgba = await controller.snapshot(
        width: targetWidth,
        height: targetHeight,
      );
      if (rgba == null || rgba.length < targetWidth * targetHeight * 4) {
        return null;
      }
      return await _encodeRgbaToPng(rgba, targetWidth, targetHeight);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _encodeRgbaToPng(
    Uint8List rgba,
    int width,
    int height,
  ) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  @visibleForTesting
  static String formatTrackLabel({
    required Map<String, String> metadata,
    required String fallbackPrefix,
    required int displayIndex,
  }) => _trackLabel(
    metadata: metadata,
    fallbackPrefix: fallbackPrefix,
    displayIndex: displayIndex,
  );

  static String? _trackLanguage(Map<String, String> metadata) {
    final lang = (metadata['language'] ?? metadata['LANGUAGE'] ?? '').trim();
    if (lang.isEmpty || lang.toLowerCase() == 'und') return null;
    return lang;
  }

  static String _trackLabel({
    required Map<String, String> metadata,
    required String fallbackPrefix,
    required int displayIndex,
  }) {
    final title = (metadata['title'] ?? metadata['TITLE'] ?? '').trim();
    final language = _trackLanguage(metadata);
    if (title.isNotEmpty && language != null) {
      if (title.toLowerCase().contains(language.toLowerCase())) return title;
      return '$title ($language)';
    }
    if (title.isNotEmpty) return title;
    if (language != null) return '$fallbackPrefix $displayIndex ($language)';
    return '$fallbackPrefix $displayIndex';
  }
}
