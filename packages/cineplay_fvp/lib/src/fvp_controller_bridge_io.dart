import 'dart:async';
import 'dart:ui' as ui;

import 'package:cineplay/cineplay.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart';
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
) {
  try {
    final info = controller.getMediaInfo();
    final streams = info?.audio;
    if (streams == null || streams.isEmpty) return const [];
    return [
      for (var i = 0; i < streams.length; i++)
        FVideoAudioTrack(
          id: i,
          label: labelFormatter(
            metadata: streams[i].metadata,
            fallbackPrefix: 'Audio',
            displayIndex: i + 1,
          ),
          language: languageExtractor(streams[i].metadata),
        ),
    ];
  } catch (_) {
    return const [];
  }
}

int? activeAudioTrackId(VideoPlayerController controller) {
  try {
    final active = controller.getActiveAudioTracks();
    if (active == null || active.isEmpty) return null;
    return active.first;
  } catch (_) {
    return null;
  }
}

bool selectAudioTrack(VideoPlayerController controller, int? trackId) {
  try {
    controller.setAudioTracks(trackId == null ? const [-1] : [trackId]);
    return true;
  } catch (_) {
    return false;
  }
}

List<FVideoSubtitleTrack> subtitleTracks(
  VideoPlayerController controller,
  String Function({
    required Map<String, String> metadata,
    required String fallbackPrefix,
    required int displayIndex,
  })
  labelFormatter,
  String? Function(Map<String, String> metadata) languageExtractor,
) {
  try {
    final info = controller.getMediaInfo();
    final streams = info?.subtitle;
    if (streams == null || streams.isEmpty) return const [];
    return [
      for (var i = 0; i < streams.length; i++)
        FVideoSubtitleTrack(
          id: i,
          label: labelFormatter(
            metadata: streams[i].metadata,
            fallbackPrefix: 'Subtitle',
            displayIndex: i + 1,
          ),
          language: languageExtractor(streams[i].metadata),
        ),
    ];
  } catch (_) {
    return const [];
  }
}

int? activeSubtitleTrackId(VideoPlayerController controller) {
  try {
    final active = controller.getActiveSubtitleTracks();
    if (active == null || active.isEmpty) return null;
    final id = active.first;
    return id < 0 ? null : id;
  } catch (_) {
    return null;
  }
}

bool selectSubtitleTrack(VideoPlayerController controller, int? trackId) {
  try {
    controller.setSubtitleTracks(trackId == null ? const [-1] : [trackId]);
    return true;
  } catch (_) {
    return false;
  }
}

bool setExternalSubtitle(VideoPlayerController controller, String uri) {
  if (uri.trim().isEmpty) return false;
  try {
    controller.setExternalSubtitle(uri);
    return true;
  } catch (_) {
    return false;
  }
}

List<FVideoChapter> chapters(VideoPlayerController controller) {
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

Future<bool> stepFrames(VideoPlayerController controller, int frames) async {
  if (frames == 0) return true;
  try {
    await controller.step(frames: frames);
    return true;
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> captureFramePng(
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

Future<Uint8List?> _encodeRgbaToPng(
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
