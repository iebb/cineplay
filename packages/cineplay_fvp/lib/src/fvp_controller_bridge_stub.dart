import 'package:cineplay/cineplay.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

List<FVideoAudioTrack> audioTracks(
  VideoPlayerController controller,
  String Function({
    required Map<String, String> metadata,
    required String fallbackPrefix,
    required int displayIndex,
  })
  labelFormatter,
  String? Function(Map<String, String> metadata) languageExtractor,
) => const [];

int? activeAudioTrackId(VideoPlayerController controller) => null;

bool selectAudioTrack(VideoPlayerController controller, int? trackId) => false;

List<FVideoSubtitleTrack> subtitleTracks(
  VideoPlayerController controller,
  String Function({
    required Map<String, String> metadata,
    required String fallbackPrefix,
    required int displayIndex,
  })
  labelFormatter,
  String? Function(Map<String, String> metadata) languageExtractor,
) => const [];

int? activeSubtitleTrackId(VideoPlayerController controller) => null;

bool selectSubtitleTrack(VideoPlayerController controller, int? trackId) =>
    false;

bool setExternalSubtitle(VideoPlayerController controller, String uri) => false;

List<FVideoChapter> chapters(VideoPlayerController controller) => const [];

Future<bool> stepFrames(VideoPlayerController controller, int frames) async =>
    false;

Future<Uint8List?> captureFramePng(
  VideoPlayerController controller, {
  int? width,
  int? height,
}) async => null;
