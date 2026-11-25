import 'dart:collection';
import 'dart:typed_data';

import 'video_source.dart';

import 'video_thumbnail_backend_stub.dart'
    if (dart.library.io) 'video_thumbnail_backend_io.dart'
    as backend;

class FVideoThumbnailRequest {
  const FVideoThumbnailRequest({
    required this.source,
    required this.position,
    this.maxWidth = 240,
    this.quality = 72,
  }) : assert(maxWidth > 0),
       assert(quality >= 0 && quality <= 100);

  final FVideoSource source;
  final Duration position;
  final int maxWidth;
  final int quality;
}

/// A host-supplied thumbnail implementation for platforms or media sources
/// that need a custom decoder, authenticated requests, or an existing cache.
typedef FVideoThumbnailProvider =
    Future<Uint8List?> Function(FVideoThumbnailRequest request);

/// Thumbnail generation used by both [FVideoPlayer] and host apps.
abstract final class FVideoThumbnail {
  /// Replaces the built-in platform thumbnailer used by [generateRequest].
  ///
  /// Playback backend adapters install a decoder here for platforms without a
  /// suitable native thumbnailer. A widget-level thumbnail provider still takes
  /// precedence because it never reaches [generateRequest].
  static FVideoThumbnailProvider? platformProvider;

  static Future<Uint8List?> generate({
    required String source,
    required Duration position,
    int maxWidth = 240,
    int quality = 72,
  }) {
    final uri = Uri.tryParse(source);
    final windowsPath = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(source);
    final videoSource = !windowsPath && uri != null && uri.hasScheme
        ? FVideoSource.uri(uri)
        : FVideoSource.file(source);
    return generateRequest(
      FVideoThumbnailRequest(
        source: videoSource,
        position: position,
        maxWidth: maxWidth,
        quality: quality,
      ),
    );
  }

  static Future<Uint8List?> generateRequest(FVideoThumbnailRequest request) {
    if (request.position.isNegative) {
      throw ArgumentError.value(
        request.position,
        'request.position',
        'must not be negative',
      );
    }
    if (request.maxWidth <= 0) {
      throw ArgumentError.value(
        request.maxWidth,
        'request.maxWidth',
        'must be greater than zero',
      );
    }
    if (request.quality < 0 || request.quality > 100) {
      throw ArgumentError.value(
        request.quality,
        'request.quality',
        'must be between zero and 100',
      );
    }
    final provider = platformProvider;
    if (provider != null) return provider(request);
    return backend.generateThumbnail(
      source: request.source,
      position: request.position,
      maxWidth: request.maxWidth,
      quality: request.quality,
    );
  }
}

/// Bounded LRU cache and in-flight deduplicator for scrub preview thumbnails.
///
/// Quantizes requested positions into [bucketDuration] intervals so scrubbing
/// back and forth across a timeline reuses decoded frames instead of repeatedly
/// invoking native decoders or HTTP range requests.
class FVideoThumbnailCache {
  FVideoThumbnailCache({
    this.maxEntries = 48,
    this.bucketDuration = const Duration(milliseconds: 1000),
  }) : assert(maxEntries > 0),
       assert(bucketDuration > Duration.zero);

  final int maxEntries;
  final Duration bucketDuration;

  final LinkedHashMap<String, Uint8List> _entries =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List?>> _inFlight = {};

  int get length => _entries.length;

  Duration quantizePosition(Duration position) {
    if (position <= Duration.zero) return Duration.zero;
    final bucketMs = bucketDuration.inMilliseconds;
    if (bucketMs <= 0) return position;
    final quantizedMs = (position.inMilliseconds ~/ bucketMs) * bucketMs;
    return Duration(milliseconds: quantizedMs);
  }

  Future<Uint8List?> resolve(
    FVideoThumbnailRequest request, {
    FVideoThumbnailProvider? provider,
  }) {
    final quantized = quantizePosition(request.position);
    final key =
        '${request.source.kind.name}:${request.source.location}|${quantized.inMilliseconds}|${request.maxWidth}|${request.quality}';
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return Future<Uint8List?>.value(cached);
    }
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final quantizedRequest = FVideoThumbnailRequest(
      source: request.source,
      position: quantized,
      maxWidth: request.maxWidth,
      quality: request.quality,
    );
    final loader = provider ?? FVideoThumbnail.generateRequest;
    late final Future<Uint8List?> future;
    future = Future<Uint8List?>.sync(() => loader(quantizedRequest))
        .then((bytes) {
          if (bytes != null && bytes.isNotEmpty) {
            _entries.remove(key);
            _entries[key] = bytes;
            while (_entries.length > maxEntries) {
              _entries.remove(_entries.keys.first);
            }
          }
          return bytes;
        })
        .whenComplete(() {
          if (identical(_inFlight[key], future)) {
            _inFlight.remove(key);
          }
        });
    _inFlight[key] = future;
    return future;
  }

  void clear() {
    _entries.clear();
    _inFlight.clear();
  }
}
