import 'package:cineplay/cineplay.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'fvp_controller_bridge_stub.dart'
    if (dart.library.io) 'fvp_controller_bridge_io.dart'
    as impl;

/// Safe adapter exposing FVP/MDK track selection, container chapters, exact
/// frame stepping, and frame snapshot capture for a [VideoPlayerController].
///
/// Every method degrades gracefully (returning empty/null or no-op) when the
/// active [VideoPlayerController] is not backed by FVP/MDK (for example on web
/// or when an Android compatibility fallback uses ExoPlayer).
abstract final class FvpControllerBridge {
  static List<FVideoAudioTrack> audioTracks(VideoPlayerController controller) =>
      impl.audioTracks(controller, _trackLabel, _trackLanguage);

  static int? activeAudioTrackId(VideoPlayerController controller) =>
      impl.activeAudioTrackId(controller);

  static bool selectAudioTrack(
    VideoPlayerController controller,
    int? trackId,
  ) => impl.selectAudioTrack(controller, trackId);

  static List<FVideoSubtitleTrack> subtitleTracks(
    VideoPlayerController controller,
  ) => impl.subtitleTracks(controller, _trackLabel, _trackLanguage);

  static int? activeSubtitleTrackId(VideoPlayerController controller) =>
      impl.activeSubtitleTrackId(controller);

  static bool selectSubtitleTrack(
    VideoPlayerController controller,
    int? trackId,
  ) => impl.selectSubtitleTrack(controller, trackId);

  static bool setExternalSubtitle(
    VideoPlayerController controller,
    String uri,
  ) => impl.setExternalSubtitle(controller, uri);

  static List<FVideoChapter> chapters(VideoPlayerController controller) =>
      impl.chapters(controller);

  static Future<bool> stepFrames(
    VideoPlayerController controller,
    int frames,
  ) => impl.stepFrames(controller, frames);

  /// Captures the currently displayed frame from MDK and encodes it as PNG.
  static Future<Uint8List?> captureFramePng(
    VideoPlayerController controller, {
    int? width,
    int? height,
  }) => impl.captureFramePng(controller, width: width, height: height);

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
