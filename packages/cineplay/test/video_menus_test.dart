import 'package:cineplay/cineplay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class _FakeActions implements FVideoActions {
  double? lastSpeed;
  bool looped = false;
  BoxFit fit = BoxFit.contain;
  int rotations = 0;
  FVideoChapter? soughtChapter;

  @override
  Future<void> setPlaybackSpeed(double speed) async => lastSpeed = speed;

  @override
  Future<void> toggleLooping() async => looped = !looped;

  @override
  void toggleFit() => fit = fit == BoxFit.cover ? BoxFit.contain : BoxFit.cover;

  @override
  void rotateClockwise() => rotations = (rotations + 1) & 3;

  @override
  Future<void> seekToChapter(FVideoChapter chapter) async =>
      soughtChapter = chapter;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'CineplaySettingsMenu updates speed, loop, fit, rotation, tracks, and chapters',
    (tester) async {
      final actions = _FakeActions();
      FVideoQualityOption? selectedQuality;
      FVideoAudioTrack? selectedAudio;
      FVideoSubtitleTrack? selectedSubtitle;
      var subtitleSelectedCalled = false;
      var captured = false;

      const chapters = [
        FVideoChapter(position: Duration.zero, title: 'Intro'),
        FVideoChapter(position: Duration(minutes: 2), title: 'Main Scene'),
      ];
      const qualities = [
        FVideoQualityOption(id: '1080p', label: '1080p', height: 1080),
        FVideoQualityOption(id: '720p', label: '720p', height: 720),
      ];
      const audios = [
        FVideoAudioTrack(id: 0, label: 'Japanese (jpn)', language: 'jpn'),
        FVideoAudioTrack(id: 1, label: 'English (eng)', language: 'eng'),
      ];
      const subs = [
        FVideoSubtitleTrack(id: 0, label: 'English (eng)', language: 'eng'),
      ];

      final scope = FVideoChromeScope(
        snapshot: FVideoChromeSnapshot(
          value: const VideoPlayerValue(
            duration: Duration(minutes: 5),
            isInitialized: true,
          ),
          playbackState: FVideoPlaybackState.playing,
          displayPosition: Duration.zero,
          controlsVisible: true,
          isScrubbing: false,
          bufferingIndicatorVisible: false,
          isFullscreen: false,
          chapters: chapters,
          currentChapter: chapters.first,
        ),
        actions: actions,
        labels: const FVideoPlayerLabels(),
        previous: null,
        next: null,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CineplaySettingsMenu(
              scope: scope,
              qualities: qualities,
              selectedQualityId: '1080p',
              onSelectQuality: (q) => selectedQuality = q,
              audioTracks: audios,
              selectedAudioTrackId: 0,
              onSelectAudioTrack: (a) => selectedAudio = a,
              subtitleTracks: subs,
              selectedSubtitleTrackId: 0,
              onSelectSubtitleTrack: (s) {
                subtitleSelectedCalled = true;
                selectedSubtitle = s;
              },
              onCaptureFrame: () => captured = true,
              maxHeight: 800,
            ),
          ),
        ),
      );

      await tester.tap(find.text('1.5×'));
      expect(actions.lastSpeed, 1.5);

      await tester.tap(find.text('Loop'));
      expect(actions.looped, isTrue);

      await tester.tap(find.text('Aspect'));
      expect(actions.fit, BoxFit.cover);

      await tester.tap(find.text('Rotate'));
      expect(actions.rotations, 1);

      await tester.tap(find.text('Capture Frame'));
      expect(captured, isTrue);

      await tester.tap(find.text('720p'));
      expect(selectedQuality?.id, '720p');

      await tester.tap(find.text('English (eng)').first);
      expect(selectedAudio?.id, 1);

      await tester.tap(find.text('Off').last);
      expect(subtitleSelectedCalled, isTrue);
      expect(selectedSubtitle, isNull);

      await tester.ensureVisible(find.text('Main Scene'));
      await tester.tap(find.text('Main Scene'));
      expect(actions.soughtChapter, chapters[1]);
    },
  );
}
