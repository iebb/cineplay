import 'dart:async';

import 'package:flutter/foundation.dart';

/// Steps playback by a relative frame count (positive = forward, negative = backward).
typedef FVideoFrameStepDelegate = FutureOr<void> Function(int frames);

/// Captures the currently displayed video frame as encoded image bytes (typically PNG).
typedef FVideoSnapshotDelegate =
    FutureOr<Uint8List?> Function({int? width, int? height});

/// A chapter or timestamp marker along a video's timeline.
@immutable
class FVideoChapter {
  const FVideoChapter({required this.position, required this.title});

  final Duration position;
  final String title;

  static final RegExp _lineTimestampPattern = RegExp(
    r'(?:^|\s)[\[(]?(\d{1,2}:)?(\d{1,2}):(\d{2})[\])]?(?:\s*[-–—:|]\s*|\s+|$)',
  );

  /// Extracts sorted, deduplicated chapter markers from plain text descriptions
  /// (such as `0:00 Intro`, `01:23 Part 2`, `1:02:15 - Finale`).
  static List<FVideoChapter> parseFromText(
    String text, {
    Duration? maxDuration,
  }) {
    if (text.trim().isEmpty) return const <FVideoChapter>[];
    final bySeconds = <int, FVideoChapter>{};
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = _lineTimestampPattern.firstMatch(line);
      if (match == null) continue;
      final hoursGroup = match.group(1);
      final hours = hoursGroup == null
          ? 0
          : int.tryParse(hoursGroup.substring(0, hoursGroup.length - 1)) ?? -1;
      final minutes = int.tryParse(match.group(2) ?? '') ?? -1;
      final seconds = int.tryParse(match.group(3) ?? '') ?? -1;
      if (hours < 0 || minutes < 0 || seconds < 0 || seconds >= 60) continue;
      if (hoursGroup != null && minutes >= 60) continue;
      final position = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
      if (maxDuration != null &&
          maxDuration > Duration.zero &&
          position > maxDuration) {
        continue;
      }
      final before = line.substring(0, match.start).trim();
      final after = line.substring(match.end).trim();
      var title = after.isNotEmpty ? after : before;
      title = title.replaceFirst(RegExp(r'^[-–—:|•·]+\s*'), '').trim();
      title = title.replaceFirst(RegExp(r'\s*[-–—:|•·]+$'), '').trim();
      bySeconds.putIfAbsent(
        position.inSeconds,
        () => FVideoChapter(position: position, title: title),
      );
    }
    final result = bySeconds.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return List<FVideoChapter>.unmodifiable(result);
  }

  /// Returns the chapter active at [position], or null when [chapters] is empty
  /// or [position] precedes the first chapter.
  static FVideoChapter? activeAt(
    List<FVideoChapter> chapters,
    Duration position,
  ) {
    FVideoChapter? active;
    for (final chapter in chapters) {
      if (chapter.position <= position) {
        active = chapter;
      } else {
        break;
      }
    }
    return active;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FVideoChapter &&
          other.position == position &&
          other.title == title;

  @override
  int get hashCode => Object.hash(position, title);
}

/// A selectable video stream quality (e.g. Auto, 1080p, 720p, 480p).
@immutable
class FVideoQualityOption {
  const FVideoQualityOption({
    required this.id,
    required this.label,
    this.width,
    this.height,
    this.bitrate,
  });

  final String id;
  final String label;
  final int? width;
  final int? height;
  final int? bitrate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FVideoQualityOption &&
          other.id == id &&
          other.label == label &&
          other.width == width &&
          other.height == height &&
          other.bitrate == bitrate;

  @override
  int get hashCode => Object.hash(id, label, width, height, bitrate);
}

/// A selectable audio track exposed by the playback backend.
@immutable
class FVideoAudioTrack {
  const FVideoAudioTrack({
    required this.id,
    required this.label,
    this.language,
  });

  final int id;
  final String label;
  final String? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FVideoAudioTrack &&
          other.id == id &&
          other.label == label &&
          other.language == language;

  @override
  int get hashCode => Object.hash(id, label, language);
}

/// A selectable subtitle track (embedded or external).
@immutable
class FVideoSubtitleTrack {
  const FVideoSubtitleTrack({
    required this.id,
    required this.label,
    this.language,
    this.isExternal = false,
  });

  final int id;
  final String label;
  final String? language;
  final bool isExternal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FVideoSubtitleTrack &&
          other.id == id &&
          other.label == label &&
          other.language == language &&
          other.isExternal == isExternal;

  @override
  int get hashCode => Object.hash(id, label, language, isExternal);
}
