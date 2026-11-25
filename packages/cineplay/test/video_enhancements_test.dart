import 'dart:async';

import 'package:cineplay/cineplay.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class _StubController extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _StubController({
    Duration duration = const Duration(seconds: 100),
    Duration position = Duration.zero,
    bool isPlaying = false,
    bool isLooping = false,
    double playbackSpeed = 1,
    Size size = const Size(1280, 720),
  }) : super(
         VideoPlayerValue(
           duration: duration,
           position: position,
           isInitialized: true,
           isPlaying: isPlaying,
           isLooping: isLooping,
           playbackSpeed: playbackSpeed,
           size: size,
         ),
       );

  final List<Duration> seeks = [];
  final List<double> speeds = [];
  final List<bool> loops = [];
  int pauseCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position);
    value = value.copyWith(position: position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    speeds.add(speed);
    value = value.copyWith(playbackSpeed: speed);
  }

  @override
  Future<void> setLooping(bool looping) async {
    loops.add(looping);
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'FVideoChapter.parseFromText parses timestamps and finds active chapter',
    () {
      const description = '''
    0:00 Intro
    01:30 - Main Topic
    [05:00] Deep Dive
    1:02:15 Finale
    99:00 Out of range
    ''';

      final chapters = FVideoChapter.parseFromText(
        description,
        maxDuration: const Duration(hours: 1, minutes: 10),
      );
      expect(chapters, const [
        FVideoChapter(position: Duration.zero, title: 'Intro'),
        FVideoChapter(
          position: Duration(minutes: 1, seconds: 30),
          title: 'Main Topic',
        ),
        FVideoChapter(position: Duration(minutes: 5), title: 'Deep Dive'),
        FVideoChapter(
          position: Duration(hours: 1, minutes: 2, seconds: 15),
          title: 'Finale',
        ),
      ]);

      expect(
        FVideoChapter.activeAt(chapters, const Duration(minutes: 2))?.title,
        'Main Topic',
      );
      expect(
        FVideoChapter.activeAt(
          chapters,
          const Duration(hours: 1, minutes: 5),
        )?.title,
        'Finale',
      );
    },
  );

  test(
    'FVideoThumbnailCache quantizes buckets, deduplicates in-flight, and evicts LRU',
    () async {
      final cache = FVideoThumbnailCache(
        maxEntries: 2,
        bucketDuration: const Duration(seconds: 2),
      );
      var loads = 0;
      final completer = Completer<Uint8List?>();
      final source = const FVideoSource.network('https://example.com/v.mp4');

      final f1 = cache.resolve(
        FVideoThumbnailRequest(
          source: source,
          position: const Duration(milliseconds: 2100),
        ),
        provider: (_) {
          loads++;
          return completer.future;
        },
      );
      final f2 = cache.resolve(
        FVideoThumbnailRequest(
          source: source,
          position: const Duration(milliseconds: 3900),
        ),
        provider: (_) {
          loads++;
          return Future.value(Uint8List.fromList([9]));
        },
      );
      completer.complete(Uint8List.fromList([1, 2, 3]));

      expect(await f1, Uint8List.fromList([1, 2, 3]));
      expect(await f2, Uint8List.fromList([1, 2, 3]));
      expect(loads, 1);

      await cache.resolve(
        FVideoThumbnailRequest(
          source: source,
          position: const Duration(seconds: 6),
        ),
        provider: (_) async {
          loads++;
          return Uint8List.fromList([4]);
        },
      );
      await cache.resolve(
        FVideoThumbnailRequest(
          source: source,
          position: const Duration(seconds: 10),
        ),
        provider: (_) async {
          loads++;
          return Uint8List.fromList([5]);
        },
      );
      expect(cache.length, 2);
    },
  );

  testWidgets(
    'FVideoPlayer handles digit jump, speed brackets, frame step, rotation, fit, and loop',
    (tester) async {
      final controller = _StubController(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 20),
        isPlaying: true,
      );
      final stepped = <int>[];
      FVideoChromeScope? latestScope;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FVideoPlayer(
            source: const FVideoSource.network('https://example.com/v.mp4'),
            controller: controller,
            autofocus: true,
            videoSurfaceBuilder: (_, _) => const SizedBox.expand(),
            frameStepDelegate: stepped.add,
            snapshotDelegate: ({width, height}) => Uint8List.fromList([7, 8]),
            chapters: const [
              FVideoChapter(position: Duration.zero, title: 'Start'),
              FVideoChapter(position: Duration(seconds: 40), title: 'Middle'),
              FVideoChapter(position: Duration(seconds: 80), title: 'End'),
            ],
            chromeBuilder: (_, scope) {
              latestScope = scope;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      // Digit '5' jumps to 50% (50s).
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump(const Duration(milliseconds: 150));
      expect(controller.value.position, const Duration(seconds: 50));
      expect(latestScope?.snapshot.currentChapter?.title, 'Middle');

      // ']' steps speed up from 1.0 to 1.25; Backspace resets to 1.0.
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await tester.pump();
      expect(controller.speeds.last, 1.25);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.speeds.last, 1.0);

      // '.' pauses and invokes frameStepDelegate(1).
      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.pump();
      expect(controller.value.isPlaying, isFalse);
      expect(stepped, [1]);

      // 'R' rotates clockwise 90 deg; 'Z' toggles BoxFit.cover.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(latestScope?.snapshot.rotationQuarterTurns, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(latestScope?.snapshot.fit, BoxFit.cover);

      // Actions: toggleLooping, nextChapter, captureFrame.
      await latestScope!.actions.toggleLooping();
      await tester.pump();
      expect(latestScope?.snapshot.isLooping, isTrue);
      expect(controller.loops.last, isTrue);

      await latestScope!.actions.nextChapter();
      await tester.pump();
      expect(controller.value.position, const Duration(seconds: 80));

      final snap = await latestScope!.actions.captureFrame();
      expect(snap, Uint8List.fromList([7, 8]));
    },
  );

  testWidgets(
    'explicit toggle hides controls even with accessibleNavigation enabled',
    (tester) async {
      final controller = _StubController(isPlaying: true);
      FVideoChromeScope? latestScope;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 450),
            accessibleNavigation: true,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FVideoPlayer(
              source: const FVideoSource.network('https://example.com/v.mp4'),
              controller: controller,
              videoSurfaceBuilder: (_, _) => const SizedBox.expand(),
              chromeBuilder: (_, scope) {
                latestScope = scope;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(latestScope?.snapshot.controlsVisible, isTrue);

      latestScope!.actions.toggleControls();
      await tester.pump();
      expect(latestScope?.snapshot.controlsVisible, isFalse);

      latestScope!.actions.toggleControls();
      await tester.pump();
      expect(latestScope?.snapshot.controlsVisible, isTrue);
    },
  );

  testWidgets(
    'stationary pointer hover does not prevent auto-hide or re-show hidden controls',
    (tester) async {
      final controller = _StubController(isPlaying: true);
      FVideoChromeScope? latestScope;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 600,
              height: 360,
              child: FVideoPlayer(
                source: const FVideoSource.network('https://example.com/v.mp4'),
                controller: controller,
                controlsAutoHideDuration: const Duration(milliseconds: 500),
                videoSurfaceBuilder: (_, _) => const SizedBox.expand(),
                chromeBuilder: (_, scope) {
                  latestScope = scope;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(300, 180));
      await tester.pump();
      expect(latestScope?.snapshot.controlsVisible, isTrue);

      // Sub-pixel jitter at the same spot must not reset the hide timer.
      await tester.pump(const Duration(milliseconds: 300));
      await mouse.moveTo(const Offset(300.5, 180.5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestScope?.snapshot.controlsVisible, isFalse);

      // Moving the pointer deliberately (>= 2px) brings controls back.
      await mouse.moveTo(const Offset(320, 180));
      await tester.pump();
      expect(latestScope?.snapshot.controlsVisible, isTrue);

      await mouse.removePointer();
    },
  );
}
